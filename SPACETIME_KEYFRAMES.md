# Spacetime por keyframes: decisiones de diseño (2026-11-22)

Entrenador 4D propio de spirula para chunks de 32 frames. Junta lo que funcionó en TRiGS T2c (`HANDOVER_4D.md` §9.1, punto 11) con lo que ya funcionaba en spirula. Es diseño propio: TRiGS es AGPL y de él se toman ideas, no código. La única fórmula externa es la del split de 3DGS-MCMC (Kheradmand et al. 2024, ec. 9), que es pública.

Código:

- `src/engine/EngineSpacetime.{h,cpp}`: el registro, el encadenado de gradientes y la relocalización.
- `src/app/TrainerSpacetime.cpp`: las semillas.
- `reference/temporal/kf/`: la semilla de prueba (`st_keyframe_seed.py`), la batería (`battery_KF.ps1`), las cadenas de pruebas, la compilación (`build_kf.ps1`), las herramientas de evaluación y los parches de lo descartado. Los datos y los binarios siguen en `outputs\tc`.

## 1. Por qué T2c funcionó y lo nuestro no

**No pule una semilla: reconstruye el chunk.** Siembra 11 cohortes, una por keyframe (cada 3 frames), con solo posición y color de NAIF:

- forma isótropa pequeña, α 0,1 y vida corta (σ = 3 frames);
- cada frame queda cubierto por su cohorte, con el detalle de su keyframe;
- el entrenamiento crea la forma, alarga las vidas que sirven y apaga las que no;
- como "muerto" es α base < 0,005, la relocalización siempre tiene sitio.

**Lo nuestro hacía lo contrario.** Partíamos de una población ya entrenada (cadena, FT10) y la refinábamos. La relocalización se quedaba sin sitio porque "muerto" exigía estar apagado en todos los frames (§8.10 del handover).

## 2. Qué se toma de cada uno

| Pieza | TRiGS T2c | spirula antes | **Decisión** | Por qué |
|---|---|---|---|---|
| Semilla | Cohortes por keyframe, solo posición y color, α 0,1, escala 0,3 × distancia media a 4 vecinos, σ = 3 frames | Población de un run entrenado | **Cohortes por keyframe, como T2c** | Es la diferencia de fondo (§1) |
| Opacidad | α base × gaussiana temporal (μ, σ), corte suave en 0,01 | Spline K8 × ventana `[t0, t1]` de bordes sigmoides | **α base × gaussiana (μ, log σ) en frames; γ < 0,01 no se dibuja** | "Muerto" pasa a ser global; μ y σ tienen gradiente limpio |
| Posición | Twist SE(3) + residuo Bézier alrededor de un ancla | B-spline K16 sobre el chunk | **B-spline K16 (spirula)** | VGS guarda posiciones por muestra; la spline ya está validada (vibración y tamaño) |
| Rotación | Exponencial del twist | B-spline K8 | **B-spline K8 (spirula)**, empieza constante | Igual |
| Color | SH constantes | DC con spline K8; SH constantes | **DC K8 (spirula)** | Gracia cambia el color por frame 2,5× más que nosotros; no cuesta detalle |
| Escala y SH | Constantes y entrenadas | Constantes y entrenadas (ST10) | **Constantes y entrenadas** | Lo exige VGS y coinciden los dos |
| Fondo | 43k filas estáticas entrenadas a la vez, fondo negro, sin máscaras | Habitación entrenada y congelada; fondo SH; máscaras con margen | **Lo de spirula** | Mismo efecto (el sujeto no explica el fondo, la lección de T2) sin reentrenar la habitación |
| Apariencia por cámara | Ninguna | PPISP del run estático | **PPISP (spirula)** | Corrige exposición por cámara; T2c no la tenía y su luz quedó en 0,97 |
| Lote | 8 cámaras del mismo instante por paso | Una vista por paso; los registros promedian `--spacetime-batch` vistas | **Una vista por paso, lote de 8 en los registros** | El motor no mezcla frames en un paso; promediar 8 vistas de instantes distintos es al menos igual de bueno |
| Pérdida de opacidad | 0,01 × media(α base × γ), con γ fijo | La del motor sobre α renderizada | **La de TRiGS**, sobre todos los registros vivos en el frame del paso | Empuja lo que no hace falta a apagarse en ese frame |
| Pérdida de escala | 0,01 × media(exp s) | `mcmc_scale_reg` del motor | **La del motor** | Equivalente |
| Coherencia rígida | Twist de 3 vecinos, peso 1 | `--temporal-smooth-coherence` (solo cadena) | **No en J2a**; se añade si la vibración lo pide | T2c dio 0,21 mm y nuestras splines ya son suaves; prueba aislada primero |
| Relocalización | Cada 200 pasos de optimizador, del 8 % al 83 %; muertos = α base < 0,005; donantes por multinomial con 4 pistas; copias exactas con μ ± 0,25σ; split MCMC | Cada 100 pasos; muerto = apagado en todos los frames; split por el eje largo | **La de TRiGS**: 1600 pasos de vista (= 200 actualizaciones de lote de 8), de 1/12 a 5/6, pistas α, velocidad × σ, gradiente 2D medio y \|∂L/∂μ\| | Es la que tuvo sitio y funcionó |
| Pasos | 12k × 8 vistas = 96k renders | 20k vistas | **96k vistas** | Mismo presupuesto de renders que T2c |
| Exportación | Opacidad por frame α·γ | `frames/NNN/splat.ply` + `birth_events.tsv` | **Lo de spirula**, con α·γ | El `.vgs` ve vidas en los tramos con α·γ > 1/255 |

## 3. El registro

- **Posición:** spline K16 sobre los 32 frames. Rotación K8 (cuaterniones crudos). DC K8.
- **Opacidad en el frame t:** `sigmoid(o) · γ(t)`, con `γ = exp(−½((t − μ)/σ)²)` y `γ = 0` por debajo de 0,01.
  - μ ∈ [0, 31] y σ ∈ [0,15; 32] frames.
  - Las derivadas del logit renderizado no dividen por α pequeña:
    - `∂l/∂o = (1 − s)/(1 − a)`
    - `∂l/∂μ = z/(σ(1 − a))`
    - `∂l/∂log σ = z²/(1 − a)`
    - con `z = (t − μ)/σ`.
- **Tasas:**
  - μ y log σ: `--spacetime-window-lr`, que ahora vale 0,005 por defecto. TRiGS usa 1,6e-4 s ≈ 0,005 frames para μ y 5e-3 para log σ.
  - Lo demás, como antes: posición relativa al tamaño del splat, y la escala y los SH con las tasas del motor.
- **Semilla desde un run de cadena** (`--spacetime-init <run>`, el camino de ST7L) se adapta así:
  - α base = el pico del tramo;
  - μ = el centro del tramo;
  - σ = la longitud del tramo, así que en los extremos queda 0,88 del pico.
  - Ya no reproduce ST7L al bit. ST7L queda en git (`956d7477`) y en `bin_st`.

## 4. La semilla de keyframes

`--spacetime-init <dir>` con `seed.ply` y `motion.bin` dentro:

- `seed.ply` es un 3DGS normal: cada fila es un registro en su keyframe.
- `motion.bin` lleva 8 float32 por fila: μ, σ, velocidad y aceleración por frame de vídeo.

El entrenador ajusta la spline de posición a `x + v·dt + ½a·dt²` dentro de ±2σ, y a velocidad constante fuera. Rotación, color y α empiezan constantes.

Para la prueba en 45-76, `st_keyframe_seed.py` hace:

1. Toma 150k centros de NAIF por keyframe (recortado y con α > 0,1). La escala es 0,3 × la distancia media a 4 vecinos dentro de esa nube densa; T2c tampoco la reescala.
2. Calcula velocidad y aceleración con los 4 registros de ST7L más cercanos, por diferencias centrales, igual que el NPZ de T2c.
3. Aplica el presupuesto de 760k: reparto proporcional por keyframe; dentro de cada uno, primero el cuarto más rápido y el resto al azar.

**Pendiente para producción:** de dónde sale la velocidad. ST7L exige un run previo. Candidatos:

- el flujo óptico multivista (memoria `flow-warp-seed-test`: coloca la semilla casi perfecta);
- velocidad cero, confiando en las vidas cortas.

Se decide después de validar el entrenador con la misma semilla que T2c.

## 5. Compatibilidad

- **`.vgs`:**
  - vida `[start, end)`;
  - escala constante por registro;
  - posición, rotación, DC y opacidad por muestra.
- **`.mint`:** VGSEditor lo escribe (`editor/mintwriter.cpp`) desde los mismos chunks encoding-0. Lo que exporta a `.vgs` también exporta a `.mint`.
  - `.mint` solo admite SH 0 o 3, así que nuestro SH1 va en los huecos de SH3 y el `.mint` ocupa más que el `.vgs`.
- **No se usa** el diccionario de SH temporal del formato, porque no influye en el detalle (handover §5).

## 6. Prueba KF1 y criterio (fijado antes de ejecutar)

`battery_KF.ps1 -Name KF1`: 96k pasos y relocalización cada 1600. Se compara con T2c y con TP2M en la misma batería.

| Medida | Criterio |
|---|---|
| Tamaño | ≤ 45 MB en VGSEditor |
| Error HP 66 / 73 / 76 | ≤ TP2M + 3 % (14,50 / 12,18 / 13,08) |
| Error de máscara entera | ≤ TP2M |
| Luz | 0,97-1,02 |
| Vibración | ≤ 0,5 mm |
| Recortes de cara 73, mano 73, espalda y pelo | Tan nítidos como T2c y sin rayas |

**Si falla:** la diferencia con T2c que queda por probar es la coherencia rígida. La semilla, la pérdida de opacidad y la relocalización ya son las mismas.

**Velocidad:** ~11 pasos/s, unas 2,3 h por chunk; T2c tardó 1 h 54.

- La GPU está al 26-51 % y la CPU usa ~5 núcleos.
- El cuello está fuera de la GPU: el encadenado en CPU de 760k registros por paso y la carga de PNG.
- Se ataca después de validar la calidad. La opción natural es pasar a la GPU la evaluación y el encadenado.

## 7. Resultados

### KF1 (96k pasos, 130 min): no cumple

| Medida | Criterio | KF1 | T2c | TP2M |
|---|---|---|---|---|
| Tamaño en VGSEditor | ≤ 45 MB | 45,6 MB | | |
| Error HP 66 / 73 / 76 | ≤ 14,50 / 12,18 / 13,08 | 14,07 / 12,95 / 13,30 | 13,42 / 11,81 / 12,64 | 14,08 / 11,83 / 12,70 |
| Error de máscara entera (52-76) | ≤ TP2M | 6,45-6,93 | 5,30-5,78 | 5,54-6,11 |
| Luz | 0,97-1,02 | 0,95-0,96 | 0,97-0,99 | 1,03-1,04 |
| Vibración (mediana) | ≤ 0,5 mm | 0,19 mm | 0,21 mm | 0,30 mm |

**Recortes:**

- La cara 73 sale más blanda y más oscura que en T2c.
- La mano y la espalda están al nivel de T2c.
- Los pies tienen manchas oscuras en el suelo, como T2c y algo menos.

**Lo que se descarta:** no es falta de opacidad. En el frame 73, la α mediana es 0,053 frente a 0,040 de T2c, y el eje mayor 7,9 mm frente a 7,7 mm. La población es equivalente.

**La relocalización** mueve entre 2,6k y 1,3k registros por evento, y la cifra baja a lo largo del entrenamiento.

### KF2 y KF3: un cambio cada uno frente a KF1; ninguno se queda

| Run | Cambio | HP 66 / 73 / 76 | Máscara 52-76 | Luz | Tamaño | Tiempo |
|---|---|---|---|---|---|---|
| KF1 | — | 14,07 / 12,95 / 13,30 | 6,45-6,93 | 0,95-0,96 | 45,6 MB | 130 min |
| KF2 | Cada lote de los registros con 8 cámaras del mismo frame, como T2c | 14,21 / 13,36 / 13,47 | 6,39-6,93 | 0,93-0,95 | 45,4 MB | 119 min |
| KF3 | Consistencia profundidad-normal 0,04 → 0,1 (ya estaba activa en KF1 con 0,04) | 14,13 / 13,01 / 13,43 | 6,40-6,95 | 0,94-0,96 | 45,6 MB | 118 min |

- La cara 73 queda igual de blanda en los tres y por detrás de T2c.
- KF2 empeora algo el error HP y la luz. Se revierte; el parche está en `reference/temporal/kf/patches/KF2_same_frame.patch`.
- KF3 empata con KF1, así que no aporta. Queda el valor por defecto.
- **Consecuencia:** la optimización de velocidad que dependía de KF2 (evaluar una vez por lote del mismo frame) ya no aplica tal cual.

### KF4-KF6: lo que T2c no tiene; ninguno se queda (2026-11-23)

| Run | Cambio | HP 66 / 73 / 76 | Máscara 52-76 | Luz | Tamaño |
|---|---|---|---|---|---|
| KF4 | Sin PPISP | 14,17 / 13,09 / 13,41 | 6,66-7,11 | 0,95-0,97 | 45,6 MB |
| KF5b | Color DC constante en el chunk | 14,12 / 13,03 / 13,47 | 6,49-6,98 | 0,95-0,96 | 45,5 MB |
| KF6 | Sin darkness boost, opacity boost, overexposure reg ni SH decay | 14,17 / 13,07 / 13,31 | 6,40-6,91 | 0,95-0,96 | 45,5 MB |

- Vibración 0,18-0,19 mm en los tres, como KF1. Los tiempos no cuentan: el PC se usó a la vez.
- En los recortes, la cara 73 es la de KF1 en los tres. KF4 además pone la piel más clara y rosada que el vídeo.
- KF5 (primer intento) murió al 84 % con un acceso ilegal de CUDA en `IntersectTile.cu:440`, que ninguna otra prueba ha dado. KF5b, idéntico, terminó.
- KF4 y KF6 solo cambiaban opciones de lanzamiento: la receta de KF1 se queda. El color constante se revierte; parche en `reference/temporal/kf/patches/KF5_constant_color.patch`.
- **Conclusión:** ni el PPISP, ni la variación de color, ni las pérdidas extra de spirula explican la distancia con T2c.

## 8. Pendiente

Lo que queda distinto de T2c, una prueba cada vez frente a KF1 y con el criterio de §6:

- la habitación entrenada a la vez que el sujeto;
- el modelo de movimiento (spline frente al de T2c);
- las tasas de aprendizaje.

Después, si alguna mejora:

- de dónde sale la velocidad de la semilla para producción;
- la velocidad del entrenamiento (evaluación y encadenado en la GPU);
- probar en otro chunk.
