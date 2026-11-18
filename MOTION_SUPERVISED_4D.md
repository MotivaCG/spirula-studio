# Spacetime con movimiento observado (diseño, 2026-11-08)

Estado: **probado y descartado** (2026-11-12, §9). La pérdida de movimiento no cambia nada y la semilla única pierde frente a TP1 lejos de 60.
- **Código:**
  - `src/engine/EngineSpacetimeMotion.{h,cpp}`.
  - Ganchos en `EngineSpacetime.cpp` (2) y `TrainerSpacetime.cpp`.
  - Opciones en `TrainConfig.h` y `TrainFields.h`.
- **Scripts:** `outputs\tc\scene_flow.py`, `st_seed_naif.py`, `battery_MS.ps1`.
- **Binario:** `outputs\tc\bin_ms\spirula.exe`.
- **Gradiente:** verificado con `outputs\tc\ms_fd_check.cpp` (PASS, error relativo máximo 1,5 %).
- **Batería:** ejecutada el 2026-11-12 (`outputs\tc\MS_battery.log`). Versión 2: incorpora la revisión R76–R83 y §9.4 de `REVISION_374_20261103.md`. Los cambios están en el §7.

Origen: §13 de `POPULATION_BUILDER_4D.md`, que sitúa la pérdida de detalle frente a Gracia entre NAIF y nuestro modelo temporal, y la propuesta §9.3 de `D:\Dependencias\4DGS_Papers\_notes\REVISION_374_20261103.md`.

**Alcance:** esto es una prueba reducida de una sola pieza de §9.3, la supervisión de movimiento persistente, sobre la representación spacetime actual. Excluye las referencias locales, la rotación objetivo y la construcción de contenido nuevo. Su resultado no valida ni refuta la arquitectura completa.

## 1. Hipótesis y la única variable nueva

Con el movimiento mal estimado, el entrenamiento fotométrico no desplaza los registros. Lo que hace es recolorearlos, apagarlos o deslizarlos, y como cada registro tiene una sola escala y un solo SH para los 32 frames, el resultado es un promedio blando (la espalda de TP2 en `BACK_FEET.png`). Es una hipótesis; la causa del ablandamiento no está identificada.

Lo que ya sabemos (memoria, 2026-11-01): con RAFT multivista, la semilla queda mejor colocada (+0,8 a 1,9 dB sin entrenar), pero el entrenamiento borra esa ventaja, tanto en la cadena ingenua como en el chunk. El flujo solo se usó para inicializar. Esa mejora de PSNR no demuestra que la correspondencia sea correcta.

**Variable nueva:** que la evidencia de movimiento siga actuando durante todo el entrenamiento, como una pérdida sobre el paso de cada registro entre frames consecutivos. Todo lo demás reutiliza el entrenador spacetime actual (splines K16/K8, ventana aprendible, sala estática, PPISP del take).

Fuera de esta primera prueba, para no mezclar variables: referencias locales con rotación, rotación objetivo, nuevos SH, poda por contribución y fusión. Si la pérdida de movimiento ayuda pero los registros vecinos divergen, el siguiente paso sería añadir las referencias locales.

## 2. Datos de movimiento (offline, Python, una vez)

`outputs\tc\scene_flow.py` (nuevo) generaliza `flow_warp.flow_field` para cada par de frames consecutivos de 45-76 y **en los dos sentidos**: 31 pares × 2 = 62 campos.

- **Geometría de visibilidad del frame f:** los splats mostrados de `ST7L_clean` en f, unos 400k. NAIF solo existe de 51 a 76, y para decidir visibilidad y profundidad la geometría blanda de ST7L se acepta como compromiso. Riesgo: que acepte rayos que debían ir ocluidos (§6).
- **Por cámara de entrenamiento** (88, se excluyen las reservadas):
  - RAFT large de ida y vuelta a 632×1120, con comprobación de consistencia entre los dos sentidos.
  - Visibilidad por profundidad renderizada (ED) y alfa > 0,5.
  - El mismo par de flujos sirve para f→f+1 y para f+1→f; lo que se duplica es la resolución 3D, no el RAFT.
- **Campo hacia atrás (f+1→f):** se resuelve desde la geometría de f+1 con el flujo inverso, no invirtiendo los puntos del campo hacia delante. Así cubre también lo que aparece en f+1 sin verse en f.
- **Paso 3D por punto:** mínimos cuadrados multirrayo robustos, 3 iteraciones descartando rayos lejanos, como `flow_warp`. Por cada punto se guardan cuatro magnitudes de confianza:
  - Número de rayos aceptados.
  - Autovalor mínimo de A: cuánto condicionan los rayos la solución, no cuánto acierta.
  - **Residuo de reproyección** del punto movido en las cámaras aceptadas, en píxeles.
  - **Normal** del splat (eje corto) y su profundidad, para comprobar después que la superficie es compatible.
- **Confianza** c ∈ [0, 1], adimensional: 0 si hay menos de 3 rayos o el autovalor es < 0,3; si no, `exp(−(residuo/1 px)²)`. Los umbrales de rayos y autovalor son los de `flow_warp`.
- **Puntos sin resolver:** no se rellenan. El relleno por vecinos de `flow_warp` es solo para la semilla (§3); no es una observación.
- **Salida:** `MSF\fwd_NNN.bin` y `MSF\bwd_NNN.bin`. Cada uno contiene, por punto:
  - Posición [n, 3].
  - Paso [n, 3].
  - Normal [n, 3].
  - Confianza [n].

  Unos 400k × 10 × 4 B ≈ 16 MB por campo, ~1 GB en total.
- **Coste estimado:** 2 RAFT × 88 cámaras por par más dos resoluciones 3D, del orden de 40-60 minutos en total. Sin medir: no hay tiempos de RAFT guardados.
- **Medido en la prueba de humo** (par 60↔61, `MSF_smoke`, 2026-11-08):
  - Tiempo: 165 s por par, unos 85 min para los 31 pares.
  - Puntos resueltos: el 78,5 % de los 276k splats de ST7L con alfa > 0,1, con una mediana de 25 rayos y un paso de 2,9 mm.
  - Residuo: la mediana es de 0,14 px, así que la confianza casi siempre sale cerca de 1 (media 0,97). Como el residuo se mide tras descartar los rayos atípicos, separa poco. Lo dejo así: la confianza útil la dan el umbral de rayos y autovalor y las reglas de superficie.

## 3. Semilla: NAIF del frame 60 llevada a todo el chunk

`outputs\tc\st_seed_naif.py` (nuevo) escribe un init de `--spacetime-init`, con el mismo formato que `TP1_init`.

- **Filas:** los 336.630 splats de NAIF 60 (SH grado 1, igual que la receta), columnas en el orden de ST7L.
- **Posición por frame:** la de 60, encadenada hacia delante con `fwd` (60→76) y hacia atrás con `bwd` (60→45).
  - **Interpolación de cada paso:** se usan los puntos del campo a ≤ 5 mm con superficie compatible. Que sea compatible significa |n·n'| > 0,5 y distancia a lo largo de la normal < 3 mm. Cada punto pesa confianza / distancia.
  - **Si no hay ninguno:** media de los 8 vecinos de la semilla que sí lo tienen, como hace `flow_warp`. Esto solo vale para la semilla; la pérdida del §4 no usa relleno.
- **Rotación:** la de NAIF por la rotación local afín (`flow_warp.local_rotation`).
- **Opacidad:** la de NAIF en todos los frames, así que cada fila es un registro de todo el chunk (`birth_events` "0 r 1"). La ventana aprendible puede apagarlo donde no esté.
- **Sala:** `ST7L/frames/room.ply`.
- **Relocalización:** la de ST7 (`--spacetime-spare 0.1 --spacetime-relocate 0.01 --spacetime-relocate-every 100`), que no dio rayas.

**Limitación declarada: lo que no se ve en 60.** Las zonas ocultas en el frame 60 no tienen semilla propia. La relocalización actual clona trayectorias de registros existentes; no crea contenido nuevo desde las fotografías. Por eso se esperan huecos o zonas blandas lejos de 60, donde cambia la visibilidad. MS0 y MS1 comparten esa limitación, así que la comparación entre los dos sigue midiendo la pérdida de movimiento. Esos huecos no se atribuyen a la pérdida ni la absuelven: cuentan contra el criterio final (§5) y se anotan como limitación de la semilla.

## 4. La pérdida de movimiento (C++, spirula)

**Código nuevo** en ficheros propios: `src/engine/EngineSpacetimeMotion.{h,cpp}`. Ganchos:
- Una llamada en `engine_spacetime_after_step`, antes del paso de Adam.
- Una llamada en el `reset` de `engine_spacetime_relocate` para invalidar la fila (ver caché).
- Dos opciones en la configuración y el parser: `--spacetime-motion <dir MSF>` y `--spacetime-motion-weight w`, con 0 = apagado y por defecto 0, así que sin cambios para lo existente.

**Pérdida para el registro r en el par (f, f+1):**

    e_r = (p_r(f+1) − p_r(f)) − s_f(p_r(f))
    L   = λ · Σ_r w_r · ρ(‖e_r‖ / σ),     ρ(x) = sqrt(1 + x²) − 1   (Charbonnier)
    w_r = c_r · α_r(f)

- `p_r(t) = Σ_k b_k(t) P_k` es la spline de posición del registro.
- `s_f(x)` es el paso del campo `fwd` en x. Para el par (f−1, f) se usa `bwd` desde f, con signo: e = (p(f−1) − p(f)) − s_bwd(p(f)).
  - Se interpola como en §3: puntos a ≤ 5 mm, superficie compatible con la del registro (eje corto de su escala y rotación en f), peso confianza / distancia.
- `c_r` es la confianza agregada; vale 0 si no hay puntos compatibles, y entonces el registro queda libre.
- `α_r(f)` es la opacidad renderizada del registro en f.
- σ = 2 mm. Una correspondencia mala no se impone como verdad: la pérdida crece linealmente lejos de σ.
- **Gradientes detenidos:** `s_f`, `c_r` y `α_r` son objetivos y pesos fijos. No se deriva a través del campo (no hay jacobiano de `s_f`) ni a través de la opacidad, así que un registro no puede bajar la pérdida apagándose.
- **Gradiente** respecto a los puntos de control, sin singularidad en e = 0:

      ∂L/∂P_k = λ · w_r · e_r / (σ² · sqrt(1 + ‖e_r‖²/σ²)) · (b_k(f+1) − b_k(f))

  `b` son los pesos de la base, ya tabulados en `bpos`; para el par (f−1, f) el factor es (b_k(f−1) − b_k(f)).
- **Verificación antes de entrenar:** la pérdida y su gradiente van en una función pura del módulo.
  - Un programa de comprobación de un solo uso en `outputs\tc` (fuera del repo, sin commit) la compara con diferencias finitas en registros aleatorios.
  - Casos: e = 0, ‖e‖ ≪ σ y ‖e‖ ≫ σ.

**Elegibilidad y cuándo se aplica:**
- En cada paso, a los registros con gradiente de imagen en esa vista (`seen`, `EngineSpacetime.cpp:247-274`) y c_r > 0, para los pares (f−1, f) y (f, f+1) del frame del paso. La fotometría y el movimiento actúan sobre el mismo registro y el mismo frame.
- Un registro sin gradiente de imagen en todas las vistas del lote está fuera de cuadro u ocluido en todas. No se le aplica la pérdida en ese lote: así no se impone movimiento a lo que no se ve. Recibe supervisión en otros lotes. Es una decisión, no un descuido.
- Se suma a `acc` antes del promedio por lote y del paso de Adam, así que el término pasa por el mismo promedio y la misma escala de lr que la fotometría.

**Caché del objetivo:**
- **Contenido:** por registro y por par, `s`, `c` y la posición y normal con las que se consultó. En la CPU, con una rejilla hash de 5 mm por campo y en paralelo.
- **Cuándo se consulta de nuevo**, sin calendario fijo:
  1. Si la posición actual del registro se aleja más de 2,5 mm de la consultada, o la normal gira más de 30°. Es una comprobación por paso y barata.
  2. **De inmediato**, para el origen y el destino de cada relocalización, desde el gancho del `reset`. Una fila reutilizada nunca hereda el objetivo de otro registro.
- **Memoria:** registros × 62 entradas × 8 floats; con ~370k registros, unos 730 MB de RAM. La GPU no cambia, pero el paso por lote tiene más coste de CPU, sin medir.

**λ:**
- Una sola calibración automática, sin barrido. En los primeros 200 pasos (pérdida apagada) se mide la mediana de ‖gradiente fotométrico de posición‖ que de verdad se suma a `acc` por registro. Solo cuentan los registros elegibles (c > 0) con gradiente no nulo.
- λ se fija para que un registro con w = 1 y ‖e‖ = σ produzca, tras el mismo promedio por lote y con los mismos `b`, un gradiente igual a esa mediana.
- Si la mediana es nula o hay menos de 1.000 registros elegibles, el entrenamiento se detiene con error, en vez de seguir con un λ arbitrario.
- λ queda fijo y se escribe en el log, junto con el número de registros elegibles.

## 5. Prueba

Dos entrenamientos en orden (nunca dos trabajos de GPU a la vez), con la misma semilla `MSF_init`, la misma receta que ST7L/TP con `--opacity-reg 0.01`, la relocalización de ST7, 20k pasos y la misma semilla aleatoria. La única diferencia es la pérdida:

- **MS0, control:** sin pérdida de movimiento.
- **MS1:** con `--spacetime-motion MSF`.

**Evaluación:**
- Las mismas herramientas: `back_feet_sheet.py` (espalda y pies), `hand_views.py` (mano 73), `transplant_eval.py` (cara, error de paso alto, luz), `vib_runs.py`, `faint_records.py`, `floor_dirt.py`.
- Bytes con vgsplyseq y con VGSEditor.
- **Frames:**
  - **52, 60, 66, 73, 76** contra NAIF.
  - **45** solo contra el vídeo y Gracia: NAIF 45-50 viene de otra receta y no es una referencia comparable (POPULATION_BUILDER §7).
  - 60 es el frame de la semilla: mide cuánto detalle pierde la representación incluso en su propia referencia.
  - Los más lejanos a 60 son 76 (16 frames) y 45 (15).
- **Revisión de transiciones:** reproducción continua en el visor del PLY o del VGS para buscar nacimientos, huecos y parpadeo, no solo recortes fijos.
- **Etiqueta:** es una evaluación sobre cámaras usadas, no held-out. NAIF 60 y el PPISP vieron las 101 cámaras; excluir las reservadas solo del flujo no lo cambia.

**Criterio de éxito (fijado antes):**
1. **Detalle:** en MS1, espalda, mano, cara y vaso a nivel NAIF en 52, 66, 73 y 76, y comparables con Gracia en 45, en los recortes. Claramente más nítidos que TP1 y que MS0.
2. **Estabilidad:** sin rayas, huecos ni capas dobles visibles, también en la reproducción continua; vibración ≤ ~0,4 mm; luz sin deriva en la serie por frame.
3. **Paso alto:** el error en 66/73/76 no es peor que el de TP1.

Esto es un hito de calidad antes de comprimir, no la solución. Después quedan el tamaño con VGSEditor, el suelo y una frontera entre chunks.

**Lectura del resultado (regla de parada).** Cada regla describe lo observado en esta prueba, no una causa:
- **MS1 ≈ MS0, ambos blandos:** en esta implementación (este campo, este peso y esta representación) la pérdida persistente no aporta. Se para esta prueba, sin barrer λ ni seguir con compresión. No queda descartado que el movimiento importe: podrían fallar la cobertura del campo, su precisión o la capacidad de la representación.
- **MS0 ya nítido:** el término persistente no hace falta en esta prueba; la semilla NAIF60 movida por flujo, más el entrenamiento, basta. La pregunta pasa a ser qué diferencia esta semilla de TP1.
- **MS1 nítido cerca de 60 y blando o con huecos lejos:** el término ayuda donde hay semilla. Lo de lejos puede ser contenido no visto en 60 (la limitación del §3), error acumulado del campo, rotación o cambios de apariencia. Se revisa por región antes de elegir el siguiente diseño.
- **MS1 cumple:** solo entonces se pasa a ajustar a VGS, reducir tamaño y aplicar la poda de suelo.

**Coste aproximado (estimaciones sin medir):**
- Flujo, ~85 min (medido: 165 s por par).
- Semilla, unos minutos.
- 2 entrenamientos de 20-35 min cada uno; TP1 tardó 29 min con 1,2M registros, y MS1 añade coste de CPU por lote.
- Evaluación, ~20 min.
- Todo en una batería desatendida, `battery_MS.ps1`, con log `MS_battery.log`.

## 6. Riesgos conocidos

- **Correspondencias malas en pelo y dedos.** Mitigación: radio de 5 mm con superficie compatible, confianza con residuo de reproyección, Charbonnier, y registros sin evidencia libres.
- **Coherencia del flujo:** que la ida y la vuelta coincidan no garantiza acierto en textura repetida.
- **Cobertura medida** (prueba de humo, par 60→61, splats de NAIF 60):
  - Con las reglas del entrenador, el 62 % encuentra campo (59 % hacia atrás). Solo por distancia, el 72 % tiene un punto resuelto a ≤ 5 mm y el 92 % a ≤ 1 cm.
  - La pérdida actuará sobre unos 6 de cada 10 registros; el resto queda libre. En la semilla, el 36-40 % toma el paso de sus vecinos.
  - Si MS1 ≈ MS0, esta cobertura es una de las explicaciones posibles (R80), no una conclusión.
- **Semilla de un único frame:** deja huecos lejos de él (§3).
- **Visibilidad blanda:** la geometría de ST7L puede aceptar rayos que debían ir ocluidos.
- **Calibración de λ:** es una regla razonable, no está validada.

## 7. Cambios respecto a la versión 1 (tras REVISION_374 R76–R83 y §9.4)

| Punto | Versión 1 | Ahora |
|---|---|---|
| R78, caché y relocalización | Recálculo cada 500 pasos; una fila relocalizada heredaba hasta 400 pasos el objetivo de otro registro | Se consulta de nuevo cuando el registro se mueve > 2,5 mm o gira > 30°, y de inmediato en cada relocalización (gancho en `reset`) |
| R81, frames | "45, 52 y 73, los más lejanos": 52 está a 8 frames, y NAIF 45 no es comparable | 52/60/66/73/76 contra NAIF; 45 contra vídeo y Gracia; reproducción continua |
| R76, hacia atrás | Campo hacia delante invertido; no cubría lo que se desocluye | Campo `bwd` resuelto desde f+1 |
| R76, radio y confianza | 1 cm: mezclaba dedos y mano con vaso; confianza solo por rayos y autovalor | 5 mm con superficie compatible; confianza con residuo de reproyección; sin relleno en la pérdida |
| R77, gradiente | Faltaba 1/σ; los objetivos y pesos detenidos no estaban declarados | Fórmula completa sin singularidad, gradientes detenidos explícitos, verificación por diferencias finitas, λ calibrado con el gradiente real del acumulador y error si no hay datos |
| R80, reglas de parada | "El flujo sobra", "falta contenido nuevo" | Descripciones de lo observado, sin atribuir causas |
| §9.4, contenido no visto en 60 | "Lo cubre la relocalización" | Limitación declarada, compartida por MS0 y MS1 |
| R79, held-out | Sin etiquetar | Evaluación sobre cámaras usadas |
| R82, elegibilidad | Implícita | Explícita: mismo `seen` que la fotometría más c > 0. **No se adopta** ampliarla a registros sin gradiente de imagen en todo el lote: eso impondría movimiento a lo que está ocluido |
| R83, coste | Tiempos dados como estimación | Marcados sin medir; se añade el coste de CPU por lote |

## 8. Relación con lo ya probado

| Idea | Probado | Diferencia ahora |
|---|---|---|
| Semilla movida por RAFT | 2026-11-01: mejor semilla, el entrenamiento la borra | El flujo se mantiene como pérdida |
| Entrenamiento conjunto del chunk | ST7L (spacetime) | Igual; se añade la evidencia de movimiento |
| Movimiento coherente por vecinos | Coherencia afín CM2: funciona. Anclas de solo traslación: fallan con el vaso | No se impone movimiento compartido; cada registro sigue su propio campo local, con superficie compatible |
| Semilla nítida de NAIF | TP1: el detalle sobrevive en parte, a costa de capas | Una sola semilla para todo el chunk, sin capas encima de ST7L |
| Seguimiento con vínculos fijos (DualGSAstra) | Falló: secuencial, asociaciones fijas, población fija | Entrenamiento conjunto, sin vínculos fijos entre gaussianas; el objetivo se consulta de nuevo según la posición actual y es robusto a correspondencias malas |

## 9. Resultado (batería MS, 2026-11-12)

Tiempos: flujo 31 pares en ~30 s/par tras el primero (el humo de 165 s incluía la carga). MS1 22 min, MS0 16 min.

- **Campo:** 79-81 % de puntos resueltos por par, mediana 25 rayos, paso ~3 mm, residuo 0,17-0,19 px.
- **Semilla:** 54-62 % de los registros leídos del campo en cada paso, el resto relleno por vecinos; recorrido mediano 45->76 de 109 mm.
- **Calibración:** λ = 2,59e-8 sobre 7,0 M muestras. Funcionó.

| Frame | HP error, píxeles malos de ST7L (x1000): NAIF / TP1 / MS0 / MS1 | Máscara entera: NAIF / TP1 / MS0 / MS1 |
|---|---|---|
| 52 | 14,02 / 14,90 / 15,89 / 15,93 | 5,10 / 5,37 / 6,24 / 6,29 |
| 60 | 13,73 / 14,64 / 14,25 / 14,19 | 5,24 / 5,52 / 5,53 / 5,48 |
| 66 | 11,98 / 13,94 / 14,71 / 14,72 | 5,33 / 5,97 / 6,56 / 6,55 |
| 73 | 10,18 / 11,73 / 13,42 / 13,49 | 5,08 / 5,76 / 6,86 / 6,91 |
| 76 | 11,16 / 12,53 / 14,45 / 14,30 | 5,18 / 5,85 / 7,33 / 7,20 |

- **Vibración:** MS0 y MS1 0,44 mm de mediana, p90 2,86 mm (TP1 0,31 / 1,32).
- **Capas tenues:** 34 % de splat-frames (TP1 24 %).
- **Bytes:** VGSEditor 26,5 MB (MS0) y 26,5 MB (MS1).
- **Recortes (`MS_FACE.png`, `MS_HAND73.png`):**
  - MS0 = MS1 a simple vista.
  - En 60 están al nivel de NAIF y TP1.
  - En 73 y 76: borde del pelo desvanecido, pajitas del vaso con rayas y mano de 73 deshilachada y con manchas, peor que TP1.
- **`MS_BACK_FEET.png`:** no se generó. `back_feet_sheet.py` falla en 76 por una caja vacía; la cabeza se toma de la profundidad del píxel de la cara.

### Lectura

Posiciones del frame k frente a la semilla (`%TEMP%\ms_cmp.py`):
- Mediana 0,12-0,62 mm, igual en MS0 y MS1.
- |MS1 − MS0| de mediana 0,05 mm. El p90 de 8 mm son filas relocalizadas, distintas en cada corrida.

Conclusiones:
- El entrenamiento no saca las trayectorias de la semilla, así que el error de movimiento ya es ~0 y la pérdida no tiene nada que corregir. No es un fallo de implementación: la pérdida está calibrada y activa, simplemente no hay conflicto.
- La pérdida de detalle lejos del frame semilla no viene de la posición. Viene de que los splats de NAIF60 (escala, forma, color) son una solución de 60 y no se rehacen en 73-76: no hay densificación y la relocalización es de 1 % cada 100 pasos.
- Coincide con el oráculo de fase 0: los splats de NAIF no persisten entre frames. La escala es el bloqueo.
- Regla de parada §5 aplicada: MS1 ≈ MS0, se detiene esta implementación.

El código C++ queda sin commitear. Si se descarta del todo, se revierte con git y el parche se guarda en `outputs\tc\patches`.
