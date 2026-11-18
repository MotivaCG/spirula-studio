# Propuesta: constructor de población 4D guiado por error (trasplante desde NAIF)

Estado: **propuesta para revisión, nada implementado ni lanzado**. Fecha: 2026-11-05.

Contexto previo, en este orden:

1. `HANDOVER_4D.md`: estado completo.
2. `D:\Dependencias\4DGS_Papers\_notes\REVISION_374_20261103.md`: §5 y §9 piden exactamente este diseño.
3. `D:\Dependencias\4DGS_Papers\_notes\deep\PLAN.md`: entrenador 4D nativo.

---

## 1. Qué cambia y qué hipótesis prueba

Hoy la población del spacetime **solo puede cambiar partiendo trayectorias heredadas de RM0** (`engine_spacetime_relocate`):

- Un registro muerto (alfa pico < `min_opacity` en todo el chunk) recibe la mitad de un registro con mucha puntuación de densificación.
- Hereda su trayectoria, su color, su ventana, su escala y sus SH.
- El detalle que la semilla perdió no vuelve: el hijo es una copia desplazada del padre blando (ST7b/ST11: +0,015 de métrica, recortes iguales).

La operación nueva **trae contenido nítido de fuera de la población**:

- **Dónde:** donde el render del chunk falla de forma reproducible en varias vistas.
- **Qué:** se insertan los splats de NAIF de ese frame, que ya tienen posición, forma, color y opacidad nítidos.
- **Cómo:** como registros nuevos con vida corta y trayectoria tomada de sus vecinos.
- **Después:** el entrenamiento conjunto decide si alargan su vida (ventana aprendible).
- **Fusión:** los que coinciden entre frames se funden en un solo registro para no pagar bytes por frame.

**Hipótesis que se prueba:** al ST7L le falta detalle porque su población no contiene el contenido fino y la operación actual no puede crearlo. Si se le da contenido correcto donde falta, el entrenamiento conjunto lo conserva sin perder estabilidad.

**Lo que no prueba:** que sea la única causa (R53 de la revisión), ni que funcione en fronteras de chunk u otras tomas. Eso viene después (§9).

---

## 2. Fase 0: el oráculo, sin entrenar (decide si merece la pena programarlo)

Antes de tocar spirula, un prototipo en Python sobre ficheros que ya existen. No es un diagnóstico más: decide sí o no a la fase 1, y da el techo de bytes.

**Entrada**

- ST7L limpio: `outputs\tc\ST7L_clean\frames\NNN\splat.ply` + `birth_events.tsv`.
- NAIF (frames 51-76): `C:\Users\Victor\Documents\Gracia4DGSConverter\VIDEOTIKI\output\000000NN.ply`.
- Ambos en SH1 y en el mismo marco: el held-out del 27 de octubre renderizó NAIF con las cámaras de `output_fg10` (SSIM 0,96). Se comprueba igual en el paso 1.

**Pasos**

1. **Alineación.** Renderizar NAIF y ST7L en el frame 60 desde 3 cámaras y comprobar que se superponen al vídeo.
2. **Mapa de error de detalle** por frame f ∈ {52, 60, 68, 76} y por las 101 cámaras.
   - Error = |HP(render ST7L) − HP(vídeo)| dentro de la máscara, con HP un paso alto (diferencia de gaussianas, σ 1 y 4 px).
   - Mide **detalle que falta o sobra**, no desvíos de color de baja frecuencia.
   - Umbral: percentil alto por cámara.
   - Las fotografías no se modifican: el paso alto solo define dónde mirar.
3. **Regiones 3D confirmadas.**
   - Los píxeles de error se retroproyectan con la profundidad mediana del render de ST7L (la de T = 0,5, como FRoG).
   - Un punto 3D se acepta si en ≥ 3 cámaras más que lo ven (test de profundidad) también cae en error.
   - Resultado: una nube de "zonas sin detalle" por frame.
4. **Trasplante oráculo.** En cada frame f, dentro de las zonas confirmadas (radio 1 cm):
   - se quitan los registros de ST7L que se dibujan allí;
   - se ponen los splats de NAIF de f que caen allí.
   - Se renderiza.
5. **Persistencia posible.** Cada splat trasplantado en f se mueve a f+1 con el movimiento de sus vecinos de ST7L (ajuste afín de los registros vecinos a 2 cm, el mismo de la coherencia).
   - Se busca su pareja en el trasplante de f+1: distancia < 0,5 × tamaño del splat, ΔRGB < 0,05, escala ±30 %.
   - La fracción emparejada a 1, 4 y 8 frames dice cuánto se podrá fundir.
6. **Bytes.**
   - Se escriben los 32 frames trasplantados con `birth_events.tsv`, de dos formas: a) cada splat trasplantado = registro de 1 frame (cota pesimista); b) parejas del paso 5 fundidas en un registro.
   - Se codifican con `vgsplyseq --chunk 32`.
   - Se comparan con ST7L con la misma herramienta y el mismo grado SH.

**Criterio para pasar a la fase 1** (fijado antes)

- **Detalle:** en recortes de cara (frame 60, `SMN_V1_H5_P8`), pelo y mano (frame 73, cámara 71, fuera del anillo con `hand_views.py`), el trasplante se ve **claramente más nítido que ST7L y cercano a NAIF**, sin bordes, costuras ni capas dobles visibles.
- **Bytes:** la versión fundida (b) cabe en **≤ ~200 B por splat mostrado** (vgsplyseq), o el emparejamiento a 4 frames es ≥ 50 %. Este último número no está medido: es el umbral propuesto para decidir; no hay referencia previa.
- **Si el oráculo no se ve nítido** (costuras, capas, mezcla rara): la idea de trasplantar contenido estático no funciona tal cual. Se para y se registra; no se programa la fase 1.
- **Si se ve nítido pero ni la fusión cabe en bytes:** el detalle de NAIF no es persistente a esta escala, y la decisión vuelve a ti (bytes frente a detalle), sin rebajar el detalle.

**Coste**

- CPU y renders con gsplat (venv ref4d, `-I`), sin entrenamiento.
- Unas horas de scripts, minutos de ejecución.
- Scripts en `outputs\tc\` (`transplant_oracle.py`), fuera del repo.

---

## 3. Fase 1: la operación en el entrenador spacetime

Solo si la fase 0 pasa. Un evento periódico durante el entrenamiento, `engine_spacetime_transplant`, con estos pasos.

### 3.1 Mapa de error y regiones (por evento)

- **Vistas:** para cada frame del chunk, un subconjunto de cámaras (p. ej. 12, rotando entre eventos).
- **Render:** con `engine_copy_render_to_host` (rgb, profundidad, `out_median`).
- **Error y regiones:** paso alto y consenso multivista como en la fase 0 (§2, pasos 2-3).
- **Diagnóstico CEM-4DGS (falta contenido frente a capa delante):**
  - el punto retroproyectado se proyecta a otras vistas y se comparan los colores del vídeo;
  - **si coinciden**, la geometría es plausible y falta contenido: hay trasplante;
  - **si no coinciden**, sobra algo delante (pelo mal colocado): no hay trasplante y se marca el registro más cercano a la cámara como candidato a liberar.
  - Con reflejos o exposición residual el test puede fallar; ante la duda, no se crea nada (R45).

### 3.2 Candidatos

- Splats de NAIF del frame f con el centro en una región confirmada.
- Se descarta el candidato si ya hay un registro vivo en f a menos de 0,5 × su tamaño con color parecido (ya representado).
- **Donde NAIF no tiene nada no se inventa:** no hay nacimiento sin fuente.
- El presupuesto por evento es fijo (§3.6).

### 3.3 Inicialización del registro nuevo

| Atributo | Valor inicial | Origen |
|---|---|---|
| Posición (16 puntos de control) | Posición NAIF en f + desplazamiento del ajuste afín de los registros vecinos (≤ 2 cm, ponderado por opacidad) evaluado en cada punto de control | Coherencia afín (nuestra, CM32); movimiento heredado de vecinos estables (FRoG) |
| Rotación (8) | Rotación NAIF compuesta con la rotación local del ajuste afín | Igual |
| Color DC (8) | DC NAIF, constante | NAIF |
| Opacidad (8) | Logit NAIF, constante | NAIF |
| Ventana | [f − 2, f + 2], aprendible | Vida corta centrada en el frame de la evidencia (CEM, STG) |
| Escala, SH1 | Los de NAIF | NAIF (mismo grado SH) |

Adam a cero, como en la relocalización actual.

### 3.4 De dónde salen las filas

- La población total no crece por encima de `cap-max`; las filas nuevas salen de registros **inútiles**.
- **Utilidad medida:** contribución máxima renderizada a lo largo de la vida (`max_weight`, ya en upstream como `--dead-criterion max_weight`), en lugar del alfa pico.
  - Un registro tenue que sí contribuye no se libera (R29).
- **Orden de liberación:**
  1. los registros marcados como "capa delante" en §3.1;
  2. los de menor `max_weight`.
- Con `--spacetime-spare` se puede reservar un margen inicial, como hoy.

### 3.5 Fusión (bytes)

Cada K eventos:

- Dos registros trasplantados se funden en uno si:
  - tienen ventanas adyacentes o solapadas;
  - en el frame de contacto están a < 0,5 × tamaño, con ΔRGB < 0,05 y escala ±30 %.
- El fundido toma la unión de ventanas y la trayectoria del más largo; la fila del otro queda libre.
- Sin fusión, cada trasplante paga un registro; con ella, un registro puede cubrir el chunk entero, como el 60-85 % de Gracia.

### 3.6 Calendario y presupuesto

- Eventos cada N pasos durante el primer ~60 % del entrenamiento; nada en el último 30 %, para que se asiente (como la penalización de ST8, que deja de actuar al final).
- **Presupuesto por evento:** un porcentaje de las filas. El tamaño final se mide con el exportador real, no con el número de filas (R31).
- La penalización de opacidad se queda en 0 o 0,01, nunca 0,03 (rayas de ST8/ST9).

### 3.7 Código (spirula, diff mínimo)

- **Lógica:** en `src/engine/EngineSpacetime.{h,cpp}` (ya es fichero propio) o en uno nuevo `EngineSpacetimeTransplant.cpp`.
  - Lectura de los PLY de NAIF por frame.
  - Mapas de error, regiones, candidatos, inicialización, liberación y fusión.
- **Llamada:** en `TrainerSpacetime.cpp`, junto a la de relocalización (`spacetime_after_step`).
- **Flags nuevos:** `--spacetime-transplant <carpeta de PLY por frame>`, `--spacetime-transplant-every`, `--spacetime-transplant-budget`.
- **Sin cambios en upstream** salvo el registro de los flags (`TrainConfig.h`, catálogo de ayuda), como los `--spacetime-*` actuales.
- **Salida:** la de hoy (`frames/NNN/splat.ply` + `birth_events.tsv`, con registros nacidos dentro del chunk). `save_spacetime` hoy escribe "todos nacen en 0"; habrá que escribir las vidas reales.
- **Si falla, se revierte** y el patch va a `outputs\tc\patches\`.

---

## 4. De dónde sale cada pieza

| Pieza | Paper | Qué tomamos | Qué es nuestro |
|---|---|---|---|
| Error localizado + consenso multivista + "falta contenido frente a capa delante" | CEM-4DGS 2511.16112 (CC BY-NC: solo ideas) | Test de color del vídeo en otra vista para decidir entre crear y quitar; su ablación (+40 % splats sin dirigir = 0 dB; dirigidos = +0,4 dB) | Error de **paso alto** (detalle) en vez de RGB; ≥ 3 vistas; sin clustering de elipses |
| Retroproyección con profundidad mediana | FRoG 2603.20857 | Profundidad de T = 0,5, robusta a flotantes | Sin atenuación de opacidad |
| Siembra donde falla el render, rayo acotado por profundidad | STG 2312.16812 (guided sampling: −2,4 dB sin él en Flame Salmon) | La idea de sembrar por error | La fuente no es aleatoria sobre el rayo: son los splats de NAIF |
| Vida corta centrada en la evidencia, ventana aprendible | STG, CEM-4DGS, SharpTimeGS 2602.02989 | Opacidad temporal con centro en el frame | Nuestra ventana sigmoide ya existe |
| Competencia persistente/transitorio con transmitancia compartida; poda por utilidad (contribución pico) | Multi4D 2606.22197 | Liberar por contribución, no por opacidad | Una sola población, sin MLP; promoción por fusión, que es diseño nuestro (R41) |
| Movimiento del nacido tomado de vecinos estables | FRoG (embedding del vecino menos deformado), coherencia afín propia | — | Ajuste afín de vecinos (CM32) |
| Contenido nítido | NAIF (nuestro estático) | — | Todo |

---

## 5. Lo que no cambia

- Chunk de 32 frames.
- Habitación entrenada y congelada.
- PPISP común (`ppisp.ckpt`).
- Sin pérdida alfa fuera de máscara.
- Sin plantillas ni esqueletos.
- Sin tocar las fotografías.
- Escala y SH constantes por registro: los SH temporales quedan fuera; el render del 2026-11-03 mostró que no dan nitidez.
- Las variables se cambian de una en una: esta prueba no mezcla SH temporal, otra calibración ni otro exportador (R49, §9.5 de la revisión).

---

## 6. Prueba de la fase 1 y criterio (fijado antes)

**Batería TP** (frames 45-76, mismo binario y receta que ST7L, 20k pasos):

- **Control:** ST7L (ya existe).
- **TP1:** ST7L + trasplante.

**Medidas**

- Recortes de cara 52/60/76, pelo, mano 73 fuera del anillo y vaso, frente a NAIF y ST7L.
- `det_eval2` como número secundario; no premia el detalle real (R23).
- Vibración (`vib_runs`).
- Capas tenues (`fade_drift`).
- Luz: render frente a vídeo por frame.
- Bytes con `vgsplyseq` y con la exportación del editor, misma herramienta, mismo SH. **Pedir permiso antes de abrir VGSEditor.**

**Éxito**

Todas a la vez:

1. Más nítido que ST7L en los recortes, de forma visible en varios frames.
2. Sin rayas, velos ni capas dobles.
3. Vibración ≤ ~0,4 mm (ST7L 0,35).
4. Sin deriva de luz.
5. ≤ ~200 B por splat mostrado.

La meta sigue siendo nivel NAIF: una mejora parcial se informa como avance, no como solución (R54).

**Parada**

- Si TP1 no es visiblemente más nítido que ST7L, no se hace un barrido de presupuestos ni de umbrales. Se registra el resultado limitado a esta implementación y se revierte.
- Si es más nítido pero rompe la estabilidad o los bytes, se informa con las cifras y decides tú.

---

## 7. Riesgos conocidos

- **Costuras y capas dobles:** los splats de NAIF y los de ST7L se ajustaron a soluciones distintas. La fase 0 lo ve antes de programar nada.
- **Popping:** registros de vida corta que aparecen y desaparecen. Los atenúan la ventana suave (borde 0,3 frames) y la fusión, y se vigila con la luz por frame y en el editor.
- **Pelo:** la profundidad mediana del pelo es incierta (FRoG lo reconoce). El consenso de ≥ 3 vistas lo filtra, pero puede dejar mechones sin trasplante.
- **Fuga en held-out:** NAIF vio todas las cámaras. Cualquier evaluación held-out de TP debe usar estáticos entrenados sin las cámaras reservadas (solo hay HOB para 45/52/60/68/76) o declararse como no válida (R25).
- **Frames 45-50:** hay PLY publicados, pero de otra receta (init `warped_init.ply`, sin densificación; `TEMPORAL_TRAINING.md` §3). Por eso la referencia NAIF es 51-76.
  - Opciones: usarlos tal cual como fuente, sabiendo que pueden ser más blandos; regenerarlos con la receta actual de Forge (requiere tu visto bueno); o no trasplantar en 45-50.
  - La fase 0 evalúa 52/60/68/76, así que no le afecta.
- **Coste de los mapas de error:** 12 vistas × 32 frames por evento, renderizados a host. Hay que medir el tiempo en la fase 1; si pesa, menos vistas por evento.

---

## 8. Qué necesito de ti

1. Visto bueno para la **fase 0** (sin GPU de entrenamiento, solo renders gsplat y CPU).
2. Confirmar que usar NAIF como fuente de contenido entra en las reglas: no es preprocesar imágenes; son nuestros propios estáticos.
3. Para la fase 1, qué hacer con los frames 45-50 (§7): usar sus PLY de la receta antigua, regenerarlos, o no trasplantar ahí.

---

## 9. Fuera de esta propuesta

- Continuidad entre chunks (al menos una frontera) y otra toma: obligatorios antes de declarar solución, después de TP.
- SH temporales: descartados como palanca de detalle; quizá para fidelidad de color, más adelante y aparte.
- Integración en Forge: después.

---

## 10. Resultado de la fase 0 (2026-11-06)

Scripts en `outputs\tc\`: `transplant_oracle.py`, `transplant_eval.py` y `battery_TPO.ps1`. Log en `TPO_battery.log`. Imágenes: `TPO_FACE.png` y `TPO_HAND73.png`.

**Regiones de error**

- Con "≥ 3 cámaras" a secas salía marcado ~70 % del cuerpo: con ~40 cámaras viendo cada punto, 3 votos se dan por azar.
- Se añadió que voten al menos la mitad de las cámaras que ven el punto.
- Así quedan 2,5-9k vóxeles de 1 cm por frame, que cubren un 7-19 % de los registros mostrados de ST7L.

**Persistencia de NAIF**

- Un splat trasplantado tiene pareja en f+1 (posición a 0,5 tamaños **y** escala ±30 %) solo en el **0,4-1,5 %** de los casos. Solo por posición, en el 20-32 %.
- El emparejador se validó con los propios registros de ST7L: 99,9 %.
- Lo que lo impide es la escala: cada frame de NAIF es otra solución. Fundir el trasplante por frame en registros persistentes no es posible.

**Error de paso alto** (×1000, sobre los píxeles donde ST7L pierde detalle; todas las cámaras)

| Frame | ST7L | NAIF | TPO_A (trasplante por frame) | TPO_K (frame clave llevado 8 frames) |
|---|---|---|---|---|
| 52 | 16,05 | 14,02 | 15,45 | 16,53 |
| 56 | 16,21 | 13,43 | 15,13 | 19,90 |
| 60 | 15,96 | 13,73 | 15,49 | 16,01 |
| 66 | 16,32 | 11,98 | 14,61 | 19,55 |
| 73 | 15,18 | 10,18 | 12,65 | 20,44 |
| 76 | 14,57 | 11,16 | 13,72 | 16,09 |

**Recortes**

- TPO_A: la mano del frame 73, vista fuera del anillo, sale claramente más nítida que en ST7L y cerca de NAIF, sin costuras. En la cara, la mejora es marginal.
- TPO_K: se rompe. Desde 2-3 frames después del frame clave aparecen manchas naranjas en el pelo y rayas en la mano.

**Bytes** (vgsplyseq, mismo SH)

| Variante | Tamaño | B por splat mostrado | Registros |
|---|---|---|---|
| ST7L_clean | 60,2 MB | 150 | 479k |
| TPO_A | 110,2 MB | 271 | 2,15M (1,53M de 1 frame) |
| TPO_K | 74,2 MB | 186 | 899k (calidad rota) |

TPO_A solo trasplanta en 51-76.

**Veredicto según el criterio fijado:**

- Hay detalle recuperable, pero parcial: cierra ~30-50 % de la distancia a NAIF.
- La única forma que lo consigue (TPO_A) cuesta 271 B por splat y no se puede fundir.
- La forma persistente (TPO_K) destruye la imagen.
- Según la regla de §2, la decisión de bytes frente a detalle vuelve al dueño. La fase 1 no se ha empezado.

---

## 11. Resultado de la fase 1 reducida (2026-11-07)

Sin C++: el entrenador spacetime ya lee registros que nacen dentro del chunk (`birth_events.tsv`). Scripts en `outputs\tc\`: `tp_init.py`, `battery_TP_init.ps1`, `battery_TP.ps1`; log `TP_battery.log`; imágenes `TP_HAND73.png`, `TP_FACE.png`, `TP_FACE_ZOOM.png`.

**Diseño**

- Init de TP1 = frames de ST7L + NAIF de cada 3.er frame (52, 55 … 76) en las regiones de la fase 0, vivos en f−1..f+1 (movidos por los vecinos de ST7L); las filas de ST7L de las regiones se quitan en su frame y su registro se corta (evento de nacimiento al volver).
- 45-50 sin trasplante (NAIF de esa receta no es comparable).
- TP0 = control: ST7L entrenado otra vez igual, sin trasplante. Ambos: binario `bin_st`, receta de ST7L, 20k pasos (18 y 29 min).

**Error de paso alto** (×1000, píxeles donde ST7L pierde detalle, 101 cámaras)

| Frame | ST7L | NAIF | TPO_A | TP0 | TP1 |
|---|---|---|---|---|---|
| 52 | 16,05 | 14,02 | 15,45 | 15,60 | 14,90 |
| 53 | 16,00 | 14,05 | 15,43 | 15,59 | 14,94 |
| 60 | 15,96 | 13,73 | 15,49 | 15,61 | 14,64 |
| 66 | 16,32 | 11,98 | 14,61 | 15,77 | 13,94 |
| 73 | 15,18 | 10,18 | 12,65 | 14,53 | 11,73 |
| 76 | 14,57 | 11,16 | 13,72 | 14,04 | 12,53 |

TP1 cierra ~55-70 % de la distancia ST7L → NAIF (TPO_A, sin entrenar, 30-50 %); el control TP0 solo ~10-20 %. Los frames que no son centro (53, 74) también mejoran.

**Recortes:** mano 73 fuera del anillo claramente más nítida que ST7L y TP0 (dedos separados en yaw +30 y pitch +25), cerca de NAIF/TPO_A, sin costuras ni rayas visibles. Cara: pelo algo más definido que TP0 en 60/73, mejora menor que en la mano.

**Estabilidad y bytes**

| | ST7L | TP0 | TP1 |
|---|---|---|---|
| Vibración mediana / p90 | 0,35 / 1,62 mm | 0,35 / 1,58 | 0,31 / 1,32 |
| Capas tenues | 18 % | 18 % | 24 % |
| Luz render/vídeo (51 → 76) | 1,037 → 1,031 | 1,030 → 1,026 | 1,036 → 1,039 |
| `.vgs` (vgsplyseq, limpio) | 60,2 MB | 61,3 MB | 94,3 MB |
| B por splat mostrado | 150 | 155 | 210 |
| Registros | 479k | 489k | 1,19M |

El entrenamiento alargó la vida de los trasplantes (vidas de 4-7 frames: 107k en el init → 502k), por eso los bytes suben de 199 B (init) a 210 B.

**Frente al criterio de §6:** 1 sí (mano clara, cara menor); 2 no visto en recortes, pero las capas tenues suben de 18 a 24 % y falta verlo en el editor; 3 sí; 4 sí; 5 límite (210 frente a ~200).

**En el editor** (exportado con VGSEditor, la misma herramienta que da los tamaños de Gracia; sale ~la mitad que vgsplyseq, no mezclar las dos): ST7L 28,7 MB, TP0 29,3 MB, **TP1 56,6 MB**; Gracia 26-45 MB por chunk. TP1 casi dobla al control. El usuario vio suciedad en el suelo. Splats mostrados con y < 3 cm por frame (45/55/65/73): TP0 15,5k / 14,5k / 15,4k / 14,3k, TP1 15,5k / 15,1k / 16,9k / 15,5k; con y < 10 cm TP1 hasta +6k (frame 65: 60,6k frente a 54,5k). La suciedad ya está casi toda en el control; el trasplante añade algo, sobre todo tenue (`floor_dirt.py`).

**Causa del tamaño:** 495k registros de trasplante, 228k cortes de registros de ST7L, vidas de trasplante alargadas en el entrenamiento, y sobre todo que el entrenamiento no apagó las capas blandas de ST7L que quedaron debajo de los trasplantes: TP1 muestra ~445-475k splats por frame frente a ~400k de TP0. Con `--opacity-reg 0` nada empuja a apagar lo redundante.

## 12. TP2: TP1 con penalización de opacidad (2026-11-07)

Una sola variable cambiada respecto a TP1: `--opacity-reg 0.01` (valor de ST7; según `HANDOVER_4D.md` con 0,01 no salen rayas, las rayas de ST8/ST9 vienen de 0,03). Misma semilla `TP1_init`, mismo binario, receta y 20k pasos. Objetivo: que el entrenamiento apague las capas blandas sobrantes y los trasplantes inútiles; los registros apagados no se exportan, así que deberían bajar a la vez los bytes, las capas tenues y la suciedad del suelo.

Scripts en `outputs\tc\`: `battery_TP2.ps1` (entrena, limpia, exporta con vgsplyseq y con VGSEditor vía `vgsedit_export.py`, evalúa), `floor_dirt.py`; log `TP2_battery.log`; imágenes `TP2_FACE.png`, `TP2_HAND73.png`; editor `VGS5_clean\TP2.vgs`.

**Criterio de éxito (fijado antes de lanzar):**

1. Exportado con VGSEditor ≤ ~40 MB (TP1 56,6; TP0 29,3).
2. Suelo: splats mostrados con y < 3 cm y con y < 10 cm no por encima de TP0.
3. Detalle: mano 73 fuera del anillo tan nítida como TP1, y error de paso alto en 66/73/76 a no más de ~0,3 del de TP1.
4. Sin rayas, vibración ≤ ~0,4 mm, sin deriva de luz.

Si no baja de tamaño sin perder la mano, el siguiente paso es menos trasplante en origen (presupuesto por región), no más penalización.

### Resultado de TP2 (32 min de entrenamiento; `TP2_battery.log`)

**Veredicto: no cumple el criterio 1.** La penalización atenúa, pero no elimina registros, y los bytes van con el número de registros.

| | TP0 | TP1 | TP2 |
|---|---|---|---|
| VGSEditor | 29,3 MB | 56,6 MB | **56,9 MB** |
| vgsplyseq | 61,3 MB | 94,3 MB | 92,3 MB |
| Registros exportados | 472k | 1,19M | 1,18M |
| Splats mostrados por frame (45 / 65 / 73) | 401k / 403k / 386k | 401k / 475k / 471k | 374k / 444k / 435k |
| Capas tenues (splat-frames con α < 0,05) | 18 % | 24 % | **30 %** |
| Vibración mediana / p90 | 0,35 / 1,58 mm | 0,31 / 1,32 | 0,30 / 1,27 |

- **Detalle:** el error de paso alto es igual que en TP1 (66: 13,94 / 13,94; 73: 11,73 / 11,70; 76: 12,53 / 12,57). La mano 73 fuera del anillo está igual de nítida que en TP1 y sin rayas (`TP2_HAND73.png`). Cumple el criterio 3.
- **Suelo, splats con y < 3 cm** (45/55/65/73): TP2 14,1k / 14,0k / 15,5k / 14,1k frente a TP0 15,5k / 14,5k / 15,4k / 14,3k.
- **Suelo, splats con y < 10 cm:** TP2 48,7k / 50,0k / 55,7k / 53,2k frente a TP0 52,9k / 52,6k / 54,5k / 51,3k.
- **Lectura del suelo:** casi en el control; ligeramente por encima en 65 y 73 con y < 10 cm. Cumple el criterio 2 por poco.
- **Luz:** sin deriva, ratio render/vídeo 1,030-1,034. Cumple el criterio 4.

**Por qué no bajan los bytes** (`faint_records.py`, pico de α de cada registro en su vida):

| | Registros | Pico < 0,02 | < 0,05 | < 0,1 | < 0,2 |
|---|---|---|---|---|---|
| TP0 | 472k | 9k | 31k | 69k | 132k |
| TP1 | 1,19M | 52k | 190k | **401k** | 645k |
| TP2 | 1,18M | 86k | 239k | 467k | 725k |

Con reg 0,01 los registros redundantes bajan a capa tenue, pero no por debajo de 1/255, así que se siguen exportando enteros. En TP1, un tercio de los registros (401k) nunca pasa de α 0,1, frente al 15 % del control. Ese tercio coincide en número con el exceso de tamaño, pero no es prescindible por definición: varios splats débiles pueden formar juntos pelo o un borde (ya vimos que quitar capas semiopacas dejaba manchas grises), y un registro opaco oculto puede sobrar. Para elegir qué quitar hace falta medir lo que aporta cada registro al render, no un umbral de opacidad.

## 13. Espalda y pies frente a Gracia y NAIF (2026-11-08)

Hoja `outputs\tc\BACK_FEET.png` (`back_feet_sheet.py`; cámara SMN_V1_H5_P15, detrás del hombre; frames 52, 66, 73; vídeo | Gracia | NAIF | TP2), zoom de la espalda en 66 `BACK66_ZOOM.png`. Gracia se renderiza en su propio sistema con nuestras cámaras trasladadas (SH exactos). Sin entrenamiento.

- **Espalda:** Gracia y NAIF se parecen: pliegues nítidos, y los dos pierden la trama fina del tejido. TP2 está claramente más blando y con rayitas verticales. En esta vista, la pérdida está en nuestro paso temporal, no en el entrenador base. La métrica laplaciana de octubre, según la cual NAIF quedaba por debajo de Gracia, no se confirma aquí a simple vista.
- **Pies:** Gracia y NAIF limpios; TP2 tiene humo oscuro alrededor y debajo de las zapatillas. NAIF es la salida publicada por frame de Forge, que pasa la poda estática con suelo y geometría; nuestra limpieza temporal (`subject_filter.py --hide`) no la aplica.
- **Suelo, medido** (mismo sistema de coordenadas): el 0,1 % más bajo de Gracia está a +9 mm y no tiene nada por debajo del suelo. Nosotros (TP0 y TP2) tenemos el 0,1 % más bajo a −40 mm y unos 2.100-2.500 splats por debajo del suelo. Por debajo de 3 cm, Gracia tiene 4.400-5.000 splats y nosotros 14.000-15.500.

**Conclusión:** la distancia a Gracia que ve el usuario se abre entre NAIF y nuestro modelo temporal. Pulir TP1/TP2, por ejemplo podándolo, no la cierra. Ver la propuesta de arquitectura en `D:\Dependencias\4DGS_Papers\_notes\REVISION_374_20261103.md` §9.3.

**Siguiente (2026-11-08):** diseño de la prueba de esa propuesta en `MOTION_SUPERVISED_4D.md`: spacetime con pérdida de movimiento persistente desde flujo multivista, semilla NAIF 60, MS0 frente a MS1. Pendiente de aprobación, nada implementado.
