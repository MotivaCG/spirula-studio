# Entrenamiento 4D de personas en spirula: estado completo para un LLM

Documento de traspaso para que cualquier LLM (o persona) pueda retomar el trabajo sin el historial de la conversación. Cubre lo que se quiere, las reglas del dueño, todo lo probado con sus números y fallos, contra qué se compara y dónde está cada cosa (datos, código, papers, herramientas).

- Fecha: 2026-11-03; actualizado el 2026-11-19, el 2026-11-20 y el 2026-11-22 (§0, §6, §8.8-8.10, §9, §10, §11).
- Dueño: Victor (MotivaCG / ScanMeNow / THE4DSCANNER).
- Idioma: conversación en español; código, comentarios y commits en inglés.
- Cifras: todas salen de logs o medidas guardadas. Donde algo no se midió, se dice.

Documentos más antiguos que este (no los sustituye; este resume y actualiza):

- `D:\Dependencias\spirula-studio\TEMPORAL_TRAINING.md`: registro detallado hasta el 2026-10-05 (en inglés). Baterías B1-B11, FC, AN, métricas de entonces y rutas.
- `D:\Dependencias\spirula-studio\TEMPORAL_SUBJECT_ONLY.md` (sin commitear): diseño v3 del chunk sin filas muertas (habitación como capa estática).
- `D:\Dependencias\spirula-studio\TEMPORAL_VGS_TEST_PLAN.md`: plan de pruebas del códec de septiembre.
- `D:\Dependencias\4DGS_Papers\_notes\deep\PLAN.md`: plan de investigación salido de los papers (25 de octubre), con el diseño del entrenador 4D nativo.
- Memoria del agente: `C:\Users\Victor\.claude\projects\D--Trabajos-FORMS-LichtFeld-Studio\memory\` (`temporal-chunk-training.md` es el diario completo; `spacetime-st9-ppisp.md` lo último).

---

## 0. Estado a 2026-11-22 (leer primero)

- **Primer resultado entregable: TRiGS T2c** (§9.1, punto 11).
  - Modo COLMAP con imágenes reales, la habitación como filas estáticas y SH1.
  - 41,2 MB en VGSEditor; error HP 66/73/76: 13,42 / 11,81 / 12,64 (mejor que TP2M).
  - Luz 0,97-0,99; vibración 0,21 mm; cara y mano limpias.
  - Es código AGPL ejecutado tal cual. Para producción hay que reimplementarlo en spirula como diseño propio.
- **Reimplementación en spirula (KF1-KF6, 2026-11-22/23):** detalle y resultados en `SPACETIME_KEYFRAMES.md`.
  - Todavía no cumple. Cara 73 más blanda que T2c, luz 0,93-0,96 y error de máscara por encima de TP2M; la vibración, 0,19 mm, es la mejor.
  - Descartado: lote de 8 cámaras del mismo instante (KF2), normal 0,1 (KF3), sin PPISP (KF4), color constante (KF5) y sin las pérdidas extra (KF6). Ninguno mueve la cara 73.
  - **Siguiente:** habitación entrenada a la vez, modelo de movimiento o tasas de aprendizaje (`SPACETIME_KEYFRAMES.md` §8).
- **Anterior mejor resultado estable:** TP2, rehecho con la binaria actual como TP2M.
  - Error HP 14,08 / 11,83 / 12,70.
  - Ocupa 59,6 MB en VGSEditor, fuera de presupuesto.
- **Mejor compromiso tamaño/detalle:** J1a (§9.1).
  - 41,3 MB; error HP 14,53 / 12,48 / 13,27.
  - Cara limpia, mano como TP2M, luz algo baja (0,95).
  - Se queda a un 3-5 % del criterio de detalle.
- **Descartado:**
  - Del 8 al 12 de noviembre (§8.9):
    - pérdida de movimiento con semilla NAIF60 (MS);
    - la cadena secuencial antigua (SEQ);
    - podar las capas tenues de TP2 (FP/FT).
  - Del 19 al 20 de noviembre (§9.1):
    - recolocación activa con forma entrenable (J1c): no añade detalle;
    - **TRiGS ejecutado tal cual en modo PLY (T1): bastante peor que ST7L en 73/76, cara borrosa**.
- **Diagnóstico de por qué fallamos:** §8.10. Hay que matizarlo con J1c: la recolocación y la forma entrenable juntas tampoco crean detalle.
  - Lo que hace TP2 mejor son sus transplantes densos de NAIF.
  - Su coste en tamaño está en los ~470k registros tenues que los acompañan.
- **Código:**
  - `Gracia` está fusionada en `TemporalChunk` (commit `b1bc0608`); la binaria es `outputs\tc\bin_merge`.
  - El entrenador por keyframes (KF1) está **sin commitear** en el árbol; su binaria es `outputs\tc\bin_kf`. Sus scripts están en `reference/temporal/kf/`.
  - La binaria nueva cambia valores por defecto (§6). Las comparaciones van contra TP2M, no contra el TP2 antiguo.

---

## 1. Qué queremos

Secuencias 4D de personas, capturadas con un rig de cámaras que mira hacia dentro, entrenadas en **spirula** y guardadas en **`.vgs`** (formato 4D propio del dueño). El resultado tiene que cumplir tres cosas a la vez:

1. **Detalle de nivel estático (NAIF).** Es innegociable. Pelo, cara, manos, objetos en la mano (el vaso tiki, la botella) tienen que verse tan nítidos como en un modelo entrenado frame a frame. Palabras del dueño: "un gaussian sin detalle es simplemente inútil". Nunca proponer quedarse con menos detalle como resultado.
2. **Estabilidad temporal**, al nivel de Gracia o mejor:
   - sin vibración de posición por splat;
   - sin parpadeo de color ni de opacidad;
   - sin deriva de luz a lo largo del chunk;
   - sin saltos entre chunks.
3. **Tamaño.** Los registros `.vgs` tienen que persistir en el tiempo; si cada frame es independiente, el archivo explota (NAIF ocupa 260 MB para 26 frames). Presupuesto aceptado: **hasta ~200 B por splat mostrado** por chunk de 32 frames, "o un poco más". Antes era ~150 B, el nivel de Gracia.

Lo que existe hoy no cumple las tres a la vez:

| Opción | Detalle | Estabilidad | Tamaño |
|---|---|---|---|
| NAIF, estático por frame | sí | no (parpadeo de luz) | no |
| Gracia | sí | sí | sí, pero su método es privado |
| Lo nuestro, mejor caso ST7L | no (más blando) | sí | sí |

---

## 2. Reglas del dueño (obligatorias)

**Método**

- **Los papers son piezas, no plantillas.** "La idea no es copiar ninguno sino coger lo que se adapte a lo nuestro." Al proponer, decir de qué paper sale cada mecanismo y por qué encaja.
- **Código de papers: solo ideas.** No se copia código (licencias: QUEEN, Mobile-4DGS, FreeTimeGS…).
- **Nada de SMPL, esqueletos ni huesos.**
- **Nada de preprocesar imágenes:** ni sharpening ni superresolución. El flujo óptico como *análisis* sí vale.
- **Nunca limpiar el fondo en el entrenamiento** (pérdida alfa fuera de máscara). Provocó falsa transparencia. La habitación se entrena y se poda después.
- **Chunks de 32 frames.** Los chunks cortos se rechazaron porque vibran en cada corte.
- **Cada experimento debe poder mejorar el resultado**, con el criterio de éxito escrito *antes* de lanzarlo. Nada de bucles de diagnóstico ("das vueltas en círculos").
- **No lanzar baterías nuevas sin el visto bueno explícito** del dueño.

**Cómo juzgar**

- Nunca dar una variante por buena solo por métricas. Mirar recortes a resolución nativa (pelo, cara, manos, vaso) en varios frames del chunk, comparar con NAIF y con la mejor anterior, y comprobar la deriva de luz.
- La métrica laplaciana de "detalle" premia rayas y vello falso.
- No inventar cifras: si algo no se midió, decir "no medido".
- Antes de proponer algo, buscar en la memoria y en los docs si ya se probó o se prohibió.

**Repositorios**

- **Diff mínimo frente a upstream** en spirula y SMNForge: lógica nueva en ficheros propios, hooks cortos en el código original, nada de refactorizar upstream.
- **Nada de código muerto.** Los experimentos fallidos se revierten por git; el patch se guarda en `outputs/tc/patches/`. Nada de flags muertos ni comentarios-historia.
- Comentarios de 3 líneas como máximo (el build de spirula falla con bloques más largos).
- **Commits:** preguntar antes de hacer commit y antes de push. **Nunca añadir co-autor** (ni "Co-Authored-By" ni nada parecido).

**Máquina**

- Nunca borrar `build/` (lleva vcpkg dentro). Nunca tocar `build_temporal_cuda_vs2022`.
- Un solo trabajo de GPU a la vez.
- Los trabajos largos se lanzan desacoplados: `Start-Process powershell -File ... -WindowStyle Hidden`. Las tareas en segundo plano del agente mueren a los ~30 min-2 h. No sondear el progreso.
- **Preguntar antes de lanzar ejecutables con GUI** (VGSEditor, LichtFeld-Studio.exe).
- Las descargas necesitan permiso.
- Código descargado = no fiable. Se ejecuta con el venv `D:\Dependencias\ref4d\venv\Scripts\python.exe -I -X utf8`, desde `$env:TEMP`.

**No tocar**

- La copia de trabajo de Forge (`D:\Trabajos\ScanMeNow\RaspberrySoft\SMNForge`, el dueño está en la rama `GraciaTrain`).
- El worktree de VGSFileFormat. Leerlos sí se puede.

**Escritura de ficheros**

- El Python que escribe ficheros del repo lo hace en modo bytes.
- Los scripts se escriben con la herramienta Write, no con heredocs.

---

## 3. Datos, rig y take de prueba

- **Rig:** SMN_V1, 105 cámaras en una esfera que miran al centro; 101 cámaras usadas en el take. En coordenadas normalizadas el radio es ~0,94 y la separación entre cámaras ~0,18. Las poses son idénticas en todos los frames (prior bloqueado).
- **Take de prueba:** VIDEOTIKI, frames **45-76** (un chunk de 32): dos personas, una con un vaso tiki en la mano.
  - Copia de trabajo para chunks: `D:\Gracia4DGSConverter\VIDEOTIKI_CHUNK`.
  - Entradas preparadas que usan las baterías actuales: `D:\Gracia4DGSConverter\VIDEOTIKI_CHUNK\output_fg10\.work\000000NN\undistorted`, con `images\`, `masks\`, `sparse\` y `smn\frames\room.ply`.
  - PPISP de todo el take: `...\output_fg10\ppisp.ckpt`. Para pruebas con cámaras reservadas: `outputs\tc\ppisp_ho.ckpt` (88 cámaras).
  - El take original es `C:\Users\Victor\Documents\Gracia4DGSConverter\VIDEOTIKI`. **No ejecutar Gracia/Forge sobre él**: su `output\.work` guarda los datasets de los experimentos.
- **Máquina:**
  - Windows 11, RTX 4070 (12 GB), 64 GB de RAM, VS 2022, CUDA 12.8.
  - Python del sistema: `C:\Python312`. **Su scipy está roto**; las búsquedas de vecinos usan rejilla de vóxeles en numpy.
  - Build de spirula: ver la memoria `build-env-windows.md`. Para este trabajo: `cmake --build build_tc`.

---

## 4. Contra qué se compara y dónde está

| Referencia | Qué es | Dónde |
|---|---|---|
| **NAIF** (también `BASEALL`, "estático", "Forge") | PLY por frame que publica Forge. Cada frame se entrena aparte con densificación MCMC. **Es el objetivo de detalle.** Parpadea en luz y no tiene identidades persistentes. Vio las cámaras reservadas, así que en held-out solo vale como referencia de forma. | PLY: `C:\Users\Victor\Documents\Gracia4DGSConverter\VIDEOTIKI\output\000000NN.ply`. VGS: `outputs\tc\VGS5_clean\NAIF_51_76.vgs` (260 MB, 26 frames) |
| **Gracia** | Servicio comercial 4DGS. Su entrenador es privado: solo vemos el resultado. Es la referencia de estabilidad y tamaño, y su `.vgs` se ve más nítido que nuestro estático. | `D:\Trabajos\ScanMeNow\SMNWebviewer\Playcanvas\content\data\tiki.mint` y `tiki.vgs` (también en `public\data`). Otras muestras: `D:\Trabajos\THE4DSCANNER\GraciaScenes\Samples\*.mint`. Registro a nuestro COLMAP: `gracia_to_colmap.json` (escala 1,874), ver `TEMPORAL_TRAINING.md` §2-3 |
| **RM0** | Nuestra cadena (chunk frame a frame) con el binario fusionado con upstream (receta CS1). Es la semilla de todos los ST. | `outputs\tc\RM0` |
| **ST7L** | Nuestro mejor 4D estable: entrenador spacetime sin relocalización. Más blando que NAIF. | `outputs\tc\ST7L`, `ST7L_clean`. VGS: `VGS5_clean\ST7L.vgs` (28,7 MB, SH1) |
| **FreeTimeGS** (referencia publicada) | FreeTimeGsVanilla (AGPL, uso de investigación) sobre 45-76. **Diverge en nuestro rig.** | `D:\Dependencias\ref4d` |

**Lo medido sobre Gracia (`tiki.mint` y `tiki.vgs`; herramienta `vgsrecords`):**

- 12 chunks de 32 frames, de 26 a 45 MB por chunk.
- 204-337k registros por chunk; el 60-85 % vive el chunk entero.
- 860-3000 nacimientos por frame; 178-281k splats mostrados por frame; mediana de tamaño de splat 4,5-5,2 mm.
- ~155 B por splat mostrado y chunk.
- Su rotación de población es igual que la nuestra (FG10: 343k registros, 1,9-2,3k nacimientos por frame). **El reciclado masivo no es lo que mantiene a Gracia nítido.**
- Sus registros cambian de color ~2,5× más por frame (|ΔRGB| 0,003-0,004 frente a 0,0013 nuestro).
- Vibración de posición por splat: mediana 0,55 mm.
- Los pies, plantados, quedan exactamente quietos (0,7-1,6 mm de movimiento en 45-76).
- Reinicio total cada ~192 frames (medido en `gymnastic`).
- ~10 % de renovación en cada frontera de chunk; 88-94 % de gemelos exactos entre chunks.
- `tiki.mint`: 448 MB, 372 frames.
- **No se sabe cómo consigue registros persistentes y nítidos a la vez.** Es la pregunta central.

---

## 5. El formato `.vgs` y el presupuesto

**Especificación y código**

- Spec: `D:\Trabajos\THE4DSCANNER\VGSFileFormat\FORMAT.md`; decodificador normativo: `core\src\vgsframe.cpp`.
- Un chunk es una lista de **registros**:
  - cada registro tiene su vida `[start, end)`;
  - posición, rotación, color DC y opacidad varían por muestra (la posición, como base más ≤4 términos de un diccionario);
  - **la escala es constante por registro**;
  - **SH altos:** entrada estática + entrada temporal. Cada registro elige un índice fijo (10 bits, 1024 entradas por grupo de coeficientes) en un diccionario temporal compartido cuyos valores cambian en cada muestra, sin interpolación entre muestras. Referencias: `FORMAT.md` ~41 y ~481, `vgsframe.cpp` 743-762 y 996-1023, `MINT_FORMAT.md` §6.8.
    - El formato lo hereda de `.mint`, así que Gracia también lo tiene.
    - **Medido el 2026-11-03 en `tiki.mint`, chunks 1-2:** lo usa en el 100 % de los splat-frames mostrados.
      - Color RMS sobre direcciones: SH estático 0,066 (p50), parte temporal 0,0165, casi toda variable en el tiempo.
      - Es suave: paso por frame 0,0028, frente a 0,0043 del color base.
      - Crece con el movimiento: 19 % del SH estático en splats quietos, 35 % en los que se mueven más de 9 cm.
      - Gracia es SH3 + SH temporal; NAIF y ST7L son SH1 sin parte temporal.
      - **No influye en la nitidez** (render del 2026-11-03, 101 cámaras, frames 52/60/73/76).
        - Imagen con SH temporal frente a sin él: PSNR enmascarado p50 de 41-49 dB entre ambas.
        - Detalle: igual (±0,01).
        - Ajuste al vídeo: +0,02 a +0,25 dB.
        - Recortes idénticos; la diferencia es color de baja frecuencia, no textura (`outputs\tc\GRACIA_TEMPORAL_SH.png`).
        - Descartado como palanca de detalle; a lo sumo, fidelidad de color.
    - Nuestro `vgsplyseq` escribe el diccionario temporal a cero (línea ~1765: "no temporal change"). La restricción "SH constantes" es de **nuestro exportador y entrenador**, no del formato. Corregido el 2026-11-03 tras `4DGS_Papers\_notes\REVISION_374_20261103.md` (R01).
  - ningún chunk depende de otro y no se reutilizan filas.

**Herramientas**

| Herramienta | Qué hace | Dónde |
|---|---|---|
| `vgsplyseq` | Codificador PLY-secuencia → `.vgs` (encoding 0). Registros = tramos visibles de (fila, generación) según `birth_events.tsv`. Uso: `vgsplyseq <dir> out.vgs --chunk 32` | Desplegado en `D:\Dependencias\vgsplyseq_deploy\vgsplyseq.exe`; fuente en el worktree `D:\Trabajos\THE4DSCANNER\VGSFileFormat_ply` (rama `TemporalPlyEncoderV4`, sin commitear) |
| `vgsrecords` | Estadísticas de registros de un `.vgs` | `...\VGSFileFormat_ply\build_plyseq4\encoder\Release\vgsrecords.exe` |
| VGSEditor | El dueño juzga aquí. Su exportación da el tamaño real. | `D:\Trabajos\THE4DSCANNER\VGSFileFormat\editor\build\cmake-msvc\Release\VGSEditor.exe`. Exportación automatizada por su puente MCP: script `vgsedit_export.py`, que estaba en el scratchpad de la sesión; reescribir si se perdió. **Preguntar antes de lanzarlo.** |

**Tamaños: comparar siempre con la misma herramienta y el mismo grado de SH**

| Fichero | Herramienta | Tamaño | B/splat mostrado |
|---|---|---|---|
| RM0 | vgsplyseq (`outputs\tc\VGSCMP\*.vgs`) | 58,2 MB | 144 |
| ST7L | vgsplyseq | 59,3 MB | 148 |
| ST8 | vgsplyseq | 64,8 MB | 171 |
| ST7b | vgsplyseq | 67,2 MB | ~168 (estimado) |
| ST7L | VGSEditor (SH1) | 28,7 MB | — |
| ST9_clean | VGSEditor (SH1) | 35,0 MB | — |
| NAIF 51-76 | VGSEditor (SH1) | 260 MB | — |

- Los B por splat de Gracia (~155) se midieron sobre `tiki.vgs`.
- **No se ha comprobado** que las cifras de vgsplyseq y del editor sean comparables entre sí. Las del editor son ~la mitad.

**Antes de comparar `.vgs`:**

- Limpiar siempre con `subject_filter.py --hide`. Un ST9 sin limpiar daba 7,7 mm de error de posición y flotantes a 58 m.
- Mirar la nota de RMS de posición que da la exportación del editor.

---

## 6. Código actual (spirula)

- **Repo:** `D:\Dependencias\spirula-studio`, rama **`TemporalChunk`** (árbol limpio tras `b1bc0608`).
- **Commits clave:**

| Commit | Contenido |
|---|---|
| `5d318bb9` | Cadena por chunks: habitación estática, chunks continuados, movimiento coherente, relocalización |
| `4b89db94` | Merge de upstream master (`e2d6be2f`); cambió valores por defecto (means_lr ×2, opacity_reg 0.01, accum sum…) |
| `b7d69695` | Spacetime fase 1: el chunk entrenado entero, una trayectoria por registro |
| `8a4cfb19` | Spacetime: spline de opacidad, relocalización 4D, penalización de opacidad, frames portables |

**Entrenador "cadena" (chunk frame a frame)**

- Ficheros: `src/engine/EngineTemporal.*`, `src/app/TrainerChunk.cpp`, `src/app/TemporalInputs.cpp`.
- Flags `--temporal-*`:
  - ventana deslizante;
  - warps y nacimientos;
  - suavizado de posición, rotación, opacidad y color;
  - `--temporal-smooth-coherence` (ajuste afín de los pasos de los vecinos a 2 cm);
  - `--temporal-room-ply` (habitación estática);
  - `--temporal-continue`;
  - `--temporal-relocate`;
  - `--temporal-spare`;
  - `--temporal-anchors`, apagado por defecto.

**Entrenador "spacetime" (el 4D nativo)**

- Ficheros: `src/engine/EngineSpacetime.{h,cpp}`, `src/app/TrainerSpacetime.cpp`, hooks en `TrainerCore`.
- Cada fila del sujeto es un registro VGS durante todo el chunk, con B-splines cúbicos uniformes en el tiempo:

| Atributo | Representación |
|---|---|
| Posición | K = 16 puntos de control (con 8: p90 de 1,6 mm de error frente a la cadena) |
| Rotación | K = 8 |
| Color DC | K = 8 |
| Logit de opacidad | K = 8, × una ventana suave `[t0, t1]` |
| Escala y SH | En los buffers del motor, **congeladas** (lr 0 en `configure_chunk`). Entrenarlas una vista por paso costaba 0,56 dB. |

- **Cada paso:**
  1. evalúa los registros en el frame de la vista y los escribe en los buffers vivos;
  2. el motor hace su paso normal;
  3. los gradientes se encadenan a los registros. Adam propio, sin corrección de sesgo del primer momento; media sobre `--spacetime-batch 4` vistas.
- **Penalización de opacidad:** el motor la suma dentro del optimizador, no en los gradientes, así que se reproduce en `engine_spacetime_after_step`.
- **Relocalización 4D** (`engine_spacetime_relocate`):
  - "muerto" = alfa pico por debajo de `min_opacity` en todo el chunk;
  - las fuentes se eligen por la puntuación de densificación;
  - split por el eje largo a mitad de vida, con el desplazamiento fijo en el mundo;
  - opacidad `1-sqrt(1-o)`, escalas ×0,5 / 0,85, Adam reiniciado.
- **La habitación** es el `frames/room.ply` del run de inicio, entrenado y congelado.
- **Flags:** `--spacetime-init <run>`, `--spacetime-relocate f`, `--spacetime-relocate-every N`, `--spacetime-spare`, `--spacetime-batch`.
- **Salida:** `frames/NNN/splat.ply` + `frames/birth_events.tsv`, que lee `vgsplyseq`.

**Binarios de experimento** (copias en `outputs\tc\`)

| Binario | Uso |
|---|---|
| `bin_st` | Código de `8a4cfb19`; base actual |
| `bin_rm` | Cadena fusionada |
| `bin_st10`, `bin_st11`, `bin_rs`, `bin_rt` | Experimentos ya revertidos |

**Patches revertidos** (`outputs\tc\patches\`): `RS_RT_full_20261026.patch`, `ST10_shape_20261102.patch`, `ST11_turning_split_20261102.patch`.

**SMNForge**

- El trabajo de chunks está en el commit temporal `6dd9310` (rama `TemporalChunk`) y en el worktree `SMNForge_tc`.
- `graciachunk.cpp/.h` lleva la receta, la poda de chunk, el pipeline `.vgs` y la continuación.
- **No tocar la copia de trabajo principal.**

**Actualización 2026-11-19**

| Commit | Contenido |
|---|---|
| `fe696e3f` | Código MS (`EngineSpacetimeMotion.*`, `--spacetime-motion*`) y documentos `HANDOVER_4D.md`, `MOTION_SUPERVISED_4D.md`, `POPULATION_BUILDER_4D.md`, `TEMPORAL_SUBJECT_ONLY.md`. MS está descartado (§8.9); el flag queda apagado por defecto |
| `b1bc0608` | Merge de la rama `Gracia` (117 commits: upstream hasta 2026.11.12 + SMNPrune) |

Cambios de ese merge que afectan al trabajo 4D:

- **Valores por defecto nuevos:**
  - `use_calib_warp=1` y `calib_correction=basic`: deformación por cámara contra errores de calibración. En spacetime se indexa por cámara física, a través del hook `engine_spacetime_camera`, igual que PPISP.
  - `noise_gate_peak_weight=0`.
  - `densify_min_split_opacity=0.05`, `min_weight=0.05`, `max_dead_fraction=0.02`.
  - Por esto los runs con binarias anteriores no se comparan directamente con `bin_merge`.
- **Firma nueva de `engine_save_checkpoint`:** `(dir, full, step, bg_height, basename, y_up, keep_all)`.
  - El `true` posicional de antes habría caído en `bg_height` sin avisar. Está corregido en `TrainerChunk.cpp` y `TrainerSpacetime.cpp`.
  - `keep_all` sigue descartando filas no finitas. Una fila NaN desplazaría los índices entre frames.
- **Cabecera PLY:** ahora rellena el contador con ceros (`element vertex 00000000000001266118`). `split_ply` está corregido. Python (`int()`) y `vgsplyseq` (`stoll`) lo leen bien.
- **Salida de los runs estáticos:** escriben `<run>.ply`/`.tar` en la carpeta del run en lugar de `step-*.ckpt/splat.ply`. Los frames de chunk y spacetime no cambian (`frames/NNN/splat.ply`).
- **`tools/check_ui_text.py`** limita las ayudas a 3 líneas; las ayudas `temporal_*` y `spacetime_*` se acortaron.
- **Binarias de experimento:**
  - `bin_merge`: la actual, con el merge.
  - `bin_ms`: MS.
  - `bin_st` sigue siendo la de TP1/TP2/FT10.
- **Prueba de humo del merge:** `outputs\tc\smoke_merge.ps1` → `SMK_merge`.
  - Receta de TP2 con 300 pasos.
  - Resultado: 32 frames × 1.175.535 registros, igual que `birth_events.tsv`, y `room.ply` de 90.583 filas.
- **Pendientes que vienen de `Gracia`:** las traducciones de `ppisp_from` y `export_keep_all_splats` están corrompidas ("R?utiliser"). En el merge se dejó nuestra versión en inglés.

**Spirula desplegado para Forge:** `D:\Dependencias\spirula-studio\build_tc_deploy`. Es lo que apunta el registro `HKCU\Software\SMN\Forge\Paths\Spirula`.

---

## 7. Cómo se mide (herramientas en `D:\Dependencias\spirula-studio\outputs\tc\`)

| Herramienta | Qué mide | Notas |
|---|---|---|
| `det_eval2.py --frames 52,60,68,76 RUN...` | "Detalle" = energía laplaciana render/vídeo dentro de la máscara, y ajuste enmascarado (dB) | Solo cámaras comunes a todos los runs comparados (el eval de spirula guarda vistas repetidas o variables, ~1 dB de ruido entre renders del mismo PLY). **Premia las rayas**: no basta por sí sola. |
| `holdout_sets.py`, `holdout_eval.ps1`, `holdout_score.py` | SSIM, PSNR enmascarado y ratio de textura sobre 13 cámaras reservadas (cada 8.ª), entrenando con 88 | Necesita `ppisp_ho.ckpt` |
| `vib_runs.py RUN...` | Vibración: mediana y p90 de la 2.ª diferencia de posición por registro (alfa > 0,1); estabilidad de color | Gracia 0,55 mm |
| `fade_drift.py RUN...` | % de splat-frames mostrados casi transparentes (alfa < 0,05) y cuánto se desvían | Las "capas tenues" |
| `hand_views.py` (venv ref4d, `-I`) | Cámaras virtuales fuera del anillo (yaw ±30, pitch ±25, dolly) alrededor de un punto. Mano: `45 28 71 560 980 720 1180` | Las rayas se ven fuera del anillo |
| `face_crop.py 60 SMN_V1_H5_P8 420 800 300 680 RUN...` | Recorte nativo de la cara | La cámara `SMN_V1_H5_P8` no tiene vista guardada en el frame 76 |
| `subject_filter.py <frame> in.ply out.ply --hide` | Separa sujeto y habitación por consenso de máscara (85 % de las cámaras de entrenamiento, máscara dilatada) | Igual que la poda de Forge |
| `render_one.ps1`, `battery_ST.ps1` (`ST_EXE`, `ST_EXTRA`, `ST_ITERS`) | Render de una vista por frame; batería base del spacetime | La receta completa está en `battery_ST.ps1` |
| `reference/temporal/` (en el repo) | `evaluate.py` (parpadeo regional), `splat_vibration.py`, `export_seq.py`, sonda de `.mint`… | Métricas antiguas, ver `TEMPORAL_TRAINING.md` §3 |

**Trampas de medida conocidas**

- El parpadeo regional por render no ve la vibración por splat. Medir siempre la 2.ª diferencia por splat.
- La luminancia media de los splats se confunde con la composición de la población. La luz se mide como render frente a vídeo.
- La mediana de dA2 por splat no predice el parpadeo renderizado.
- Las cachés de render se guardan por nombre de run en `q\`: purgar o usar nombres nuevos.
- Los logs mezclan ASCII y UTF-16: quitar los NUL antes de buscar.
- En PowerShell las variables no distinguen mayúsculas.
- El held-out antiguo (con niebla de cámaras vecinas) se rechazó en septiembre. El actual es un dataset por cámara reservada.

---

## 8. Todo lo probado (cronológico, con resultado)

### 8.1 Antes de la rama (contexto)

- **DualGSAstra** (rama de spirula, `docs/notes/dualgs.md`): grafo de deformación tipo DualGS con apariencia congelada. "Un desastre completo"; se abandonó por el parpadeo de luz.
- **LichtFeld:** trabajo anterior sobre el estático; ya no es el entrenador de producción.

### 8.2 Cadena por chunks: estabilidad (septiembre y principios de octubre)

| Prueba | Resultado | Destino |
|---|---|---|
| B1-B11 (ventana deslizante W6, warps, nacimientos; detalles en `TEMPORAL_TRAINING.md` §5) | B8: parpadeo regional 7,7/8,9 frente a 9,5 de Gracia y 22,4 de Forge; ajuste 30,8 frente a 31,0 de Forge | Base de la cadena |
| Integración en Forge (FC1-FC7) | FC1: sembrar un chunk desde un modelo podado pierde 4,5 dB (sin habitación) | Hay que entrenar la habitación |
| Anclas de movimiento (FC7/AN) | Mejor parpadeo y códec, pero **visualmente horrible**: el vaso se emborrona desde el frame 52; las anclas de traslación a 3 cm no siguen un objeto pequeño que gira | Revertido de la receta; el código sigue en spirula, apagado |
| Suavizado de posición/rotación de 2.º orden | Necesario para la vibración. El "oscurecimiento" de FC5 era en realidad la poda de publicación. | Se queda |
| Deriva de luz dentro del chunk | Causa: la poda de publicación quitaba la habitación, que completaba el color de splats semitransparentes | Arreglado con la **habitación como capa estática** (`--temporal-room-ply`) |
| Esconder filas en los PLY publicados | Rechazado por el dueño: "solo esconde el problema" | — |
| Vibración sin suavizado | 10 mm de mediana frente a 0,55 de Gracia | — |
| Deslizamiento de splats (pies que se deslizan 50 mm) | Causa: posición libre por frame | **Coherencia afín** (`--temporal-smooth-coherence`, CM32): deslizamiento 47,5→1,7 mm, vibración 0,31 mm, error del códec 3,98→0,46 mm, decodificado = pre-códec |
| Salto entre chunks (−85k splats) | Arreglado con `--temporal-continue` (FG8) | Se queda |
| QUEEN, refine con el códec en el bucle | El refine conjunto no compensa el error de posición | Camino muerto |

### 8.3 Cadena por chunks: el detalle (12-26 de octubre). El problema que sigue abierto

- **FG8:** el dueño dijo "se ven realmente mal" (cara y manos blandas, botella emborronada). El detalle laplaciano cae de 0,73-0,76 en la semilla a 0,50-0,57 en los frames siguientes, **también en píxeles quietos**.
- **Descartado como causa** (cada uno con su batería):
  - suavizado (CD1/CD2);
  - coherencia;
  - códec;
  - lr recalentado (LR);
  - nacimientos (BW1);
  - warp (BW2);
  - pasos ×3 (FR1);
  - escala (SC, EM2);
  - entrenar el chunk entero con parámetros por frame (JR1, peor);
  - colores y tasas (LC);
  - objetivo de warp denso desde los estáticos (MT1);
  - pool de relocalización (RG).
- **Parcial:** quitar la supervisión de profundidad/normales de MoGe da +0,01-0,04.
- **Causa raíz medida:**
  - el estático solo se mantiene nítido porque la relocalización MCMC recicla **casi toda la población en cada frame** (~414k splats en 91 refines);
  - sin densificación, la cadena estática se emborrona en 7 frames (CC1);
  - como registros VGS eso no comprime nada.
- **RD/RF** (relocalización en la cadena): RF1 da +1 dB y recortes más nítidos que FG8. Pero la versión FG9 fue un desastre por un bug de generaciones (corregido).
- **CS1** (receta consolidada): spare 0,3, relocate 0,03/300, tasas de color del estático. Detalle cercano al estático en 45-60; pelo algo más blando.
- **La relocalización de la cadena está hambrienta:** tras el frame 0 solo consigue 1-4k filas por frame, porque el destino tiene que estar muerto en los 6 frames de la ventana.

| Batería | Detalle 52/60/68/76 | `.vgs` | Veredicto |
|---|---|---|---|
| RS0 (control) | 0,635 / 0,583 / 0,564 / 0,578 | 57,1 MB | — |
| RS3 (reparto + puntuación por frame + reserva 0,6) | 0,638 / 0,559 / 0,578 / 0,623 | 65,3 MB | Recortes iguales |
| RT1 (reciclar filas apagadas) | 0,641 / 0,582 / 0,580 / 0,605 | 63,0 MB | Recortes iguales |
| RT2 (RT1 sin suavizado de opacidad) | 0,646 / 0,595 / 0,591 / 0,609 | 80 MB | Parpadeo de opacidad ×5 |

Conclusión: **la cadena frame a frame está agotada**. RS/RT revertidos.

- **Merge de upstream (RM0):** detalle 0,686 / 0,625 / 0,637 / 0,640, visiblemente más nítido que RS0; vibración 0,37 mm. Nueva base.

### 8.4 Semilla movida por flujo óptico (1 de noviembre)

- **Qué se probó:** RAFT multivista con consenso de rayos por splat (`flow_warp.py`, `flow_graph.py`).
- **Semilla:** +0,8-1,9 dB, casi el techo de un warp perfecto.
- **Tras entrenar:** la ventaja desaparece, tanto en la cadena ingenua como en el chunk (HOF ≈ HOR).
- **Conclusión:** la colocación de la semilla no es el cuello de botella.

### 8.5 Referencia FreeTimeGS (31 de octubre - 1 de noviembre)

- **Preset por defecto** (1,2M splats, relocalización 10 %): diverge hacia los 9k pasos con splats enormes delante de las cámaras. Con 1,5 % diverge igual.
- **Con la poda de gsplat:** no diverge, pero se queda con 63k splats (held-out SSIM 0,68). No es un techo justo.
- **Estado:** aparcado por el dueño. Cualquier ejecución nueva necesita una guarda de tamaño o de cercanía a cámara sin reset de opacidad.

### 8.6 Entrenador spacetime, el 4D nativo (26 de octubre - 2 de noviembre)

Diseño en `PLAN.md` ("Entrenador 4D nativo"). Detalle y ajuste con `det_eval2`, cámaras comunes, frames 52/60/68/76:

| Run | Receta | Detalle | Ajuste (dB) | Otras medidas |
|---|---|---|---|---|
| RM0 | Semilla (cadena) | 0,686 / 0,625 / 0,637 / 0,640 | 22,13 / 22,11 / 23,06 / 21,99 | Vibración 0,37 mm; tenues 14 % |
| ST4 | Fase 1, 6k pasos, opacidad constante | 0,688 / 0,632 / 0,650 / 0,683 | 21,98 / 22,08 / 22,92 / 21,83 | — |
| ST5 | + spline de opacidad K8 | +0,01-0,04 sobre RM0 | = RM0 | — |
| ST6 | + relocalización 2 %/100, reserva 0,2 | +0,05 | −0,5 dB | La relocalización muere tras la ráfaga de la reserva |
| **ST7L** | ST5, 20k pasos, sin relocalización, reg 0 | 0,719 / 0,656 / 0,664 / 0,690 | 22,13 / 22,15 / 22,95 / 21,72 | Vibración 0,35 mm; tenues 18 %; 148 B |
| ST7 | reg 0,01 + reloc 1 %/100, reserva 0,1, cap 700k | 0,741 / 0,677 / 0,685 / 0,705 | 22,05 / 22,01 / 22,91 / 21,55 | 112k relocalizados; 160 B |
| ST8 | reg 0,03 | 0,780 / 0,709 / 0,717 / 0,744 | 21,89 / 21,83 / 22,73 / 21,38 | 221k relocalizados; vibración 0,33; 171 B |
| ST9 | reg 0,03 + relocalización (`8a4cfb19`) | — | — | **Rechazado en el editor**: rayas de vello en piel, manos y vaso fuera del anillo; la mano libre se vuelve una mancha roja; 37 % de capas tenues |
| ST10 | ST7L + escala y SH entrenados por registro | −0,006..−0,011 | +0..+0,14 | **Nulo**, revertido |
| ST7b | Receta de ST7 con el binario de ST9 (control) | 0,736 / 0,669 / 0,679 / 0,704 | 22,04 / 22,05 / 22,88 / 21,52 | Tenues 31 %; vibración 0,32; 67,2 MB (+13 %) |
| ST11 | ST7b + split cuyo desplazamiento gira con el registro | 0,736 / 0,673 / 0,680 / 0,712 | 22,06 / 22,01 / 22,86 / 21,54 | **Idéntico a ST7b**, revertido |

- **Recortes** (mano fuera del anillo en el frame 73, cara en el 60): ST7L, ST7b y ST11 se ven iguales; ninguno se acerca a NAIF.
- **Rayas:** con reg 0,01 no aparecen en ninguno. Las rayas de ST8/ST9 vienen de la reg 0,03, y la ganancia de "detalle" de ST8/ST9 **eran esas rayas**.
- **Mano roja de ST9:**
  - la exportación limpia corrigió el error de codificación (7,7 → 0,5 mm) pero no la mano roja;
  - los PLY son SH1 y las cámaras frontales la renderizan color piel; el rojo solo aparece en el editor;
  - no se investigó más.

**Held-out** (13 cámaras reservadas; SSIM / PSNR enmascarado / textura):

| Frame | HOB (estático por frame) | HOR (cadena RM0) | HOS7L | HOS9 | NAIF* |
|---|---|---|---|---|---|
| 45 | 0,850 / 22,22 / 0,811 | 0,874 / 22,37 / 0,738 | 0,869 / 22,24 / 0,776 | 0,877 / 22,28 / 0,806 | 0,961 / 23,76 / 0,711 |
| 60 | 0,833 / 21,12 / 0,676 | 0,907 / 21,13 / 0,595 | 0,903 / 21,03 / 0,614 | 0,912 / 21,09 / 0,640 | 0,958 / 22,53 / 0,640 |
| 76 | 0,874 / 21,52 / 0,736 | 0,890 / 21,93 / 0,645 | 0,919 / 21,82 / 0,679 | 0,922 / 21,72 / 0,697 | 0,959 / 23,09 / 0,688 |

\*NAIF vio esas cámaras: no es comparable, solo de referencia. HOS9 sale mejor que HOS7L en números y peor a la vista: **las métricas engañaron otra vez**.

### 8.7 Lo que todo esto demuestra (y lo que no)

La revisión `4DGS_Papers\_notes\REVISION_374_20261103.md` (§6 R07-R22 y matriz §7) acota el alcance de estas conclusiones; leerla junto a esta sección.

1. **Las variantes spacetime probadas, todas sembradas desde RM0, acaban con el detalle de su semilla** más 0,03-0,05. Ni entrenar la escala y los SH constantes (ST10), ni la relocalización 4D al 1 % (ST7b), ni el corte que gira (ST11) lo mueven. Más penalización (0,03) sube la métrica a base de rayas y capas tenues.
   - Es una meseta de estas variantes, no un techo demostrado de cualquier 4D ni de cualquier inicialización.
2. **La semilla se emborrona desde el frame 1:** tras el frame 0, la cadena recicla poco (1-4k filas por frame).
   - Las recetas estáticas probadas solo se mantienen nítidas con relocalización masiva.
   - Las ~414k relocalizaciones de un frame cuentan *operaciones* (puede haber varias sobre la misma fila), no identidades finales distintas, así que no prueban que la nitidez sea incompatible con la persistencia.
3. **Descartado, en las formas concretas probadas** (no en general):
   - la colocación (flujo);
   - el suavizado;
   - la coherencia;
   - el códec;
   - los nacimientos;
   - las tasas;
   - los pasos;
   - la forma (escala y SH constantes, ST10); **los SH temporales no se han probado**;
   - la profundidad, salvo un poco.
   - El flujo solo descartó *el warp inicial*, no una supervisión de correspondencia mantenida durante el entrenamiento.
4. **Gracia demuestra que es viable en producto** (registros persistentes, nítidos, ~155 B), con una rotación de población parecida en la salida. No sabemos cómo entrena ni cuánto recicla internamente.
5. La estabilidad (vibración ~0,3 mm, luz plana, sin saltos entre chunks) y el tamaño **están resueltos para ST7L y la cadena**. Un método nuevo tiene que volver a demostrarlos, junto con el detalle.

### 8.8 Constructor de población: transplantes de NAIF (5-8 de noviembre)

Diseño en `POPULATION_BUILDER_4D.md` (§11-12). Métricas:

- **Error HP:** error de alta frecuencia (×1000, menos es mejor) en los píxeles donde a ST7L le falta detalle. Lo calcula `transplant_eval.py`.
- **Tamaño:** se mide con **VGSEditor**, el que se compara con Gracia. `vgsplyseq` da ~2× más; nunca mezclar los dos.

**Fase 0 (oráculo, sin entrenar; `transplant_oracle.py`, `TPO_battery.log`):**

1. **Los splats de NAIF no persisten:** solo el 0,4-1,5 % tiene pareja en f+1 en posición y escala. Cada frame de NAIF es una solución distinta.
2. **TPO_A, transplante por frame:** cierra el 30-50 % del hueco. Mano del 73 casi como NAIF, pero 271 B por splat mostrado.
3. **TPO_K, un keyframe NAIF cada 8 frames llevado por el movimiento de los vecinos:** roto (manchas naranjas en el pelo, rayas).

**Fase 1:**

- **TP1:** ST7L + NAIF de cada 3er frame en las regiones malas, vivos f-1..f+1, 20k pasos.
- **TP2:** TP1 + `--opacity-reg 0.01`.
- **TP0:** control, ST7L reentrenado igual sin transplantes.

| Run | HP 52 / 60 / 66 / 73 / 76 | VGSEditor | Vibración | Nota |
|---|---|---|---|---|
| ST7L | 16,05 / 15,96 / 16,32 / 15,18 / 14,57 | 28,7 MB | 0,35 mm | Base spacetime |
| NAIF | 14,02 / 13,73 / 11,98 / 10,18 / 11,16 | — | — | Referencia de detalle (frame a frame, parpadea) |
| TP0 | — / — / — / 14,53 (73) / — | 29,3 MB | — | Control |
| TP1 | 14,90 / 14,64 / 13,94 / 11,73 / 12,53 | 56,6 MB | 0,31 mm | Mano del 73 casi NAIF, pelo algo más nítido |
| **TP2** | 14,87 / 14,67 / 13,94 / 11,70 / 12,57 | **56,9 MB** | 0,30 mm | Suelo como TP0. **Falla el tamaño** |

**Por qué es tan grande:** los bytes siguen al número de **registros**. TP1 tiene 1,19 M registros y 401k de ellos nunca superan alfa 0,1 (TP0: 69k de 472k). La regularización atenúa pero no mata (las capas tenues pasan del 24 al 30 %).

**Hoja de espalda y pies** (`back_feet_sheet.py`, cámara H5_P15, frames 52/66/73):

- Espalda: Gracia ≈ NAIF; TP2 más blando y con rayas verticales. La distancia es del paso temporal, no del entrenador base.
- Pies: TP2 deja humo oscuro y unos 2,2k splats bajo el suelo.

### 8.9 Lo descartado del 8 al 12 de noviembre

**MS: pérdida de movimiento persistente desde flujo RAFT multivista, semilla NAIF60** (`MOTION_SUPERVISED_4D.md` §9, `MS_battery.log`)

- **MS1 = MS0** en error HP, vibración (0,44 mm), capas tenues (34 %) y bytes (26,5 MB).
- La λ se calibró (2,6e-8) y la pérdida estaba activa, pero las posiciones entrenadas quedan a 0,1-0,6 mm de la semilla: no había nada que corregir.
- Solo es buena en el 60. En el 73 da 13,4 (TP1 11,7): pelo que se desvanece, pajitas con rayas, mano con manchas.
- **Lección:** el detalle lejos del keyframe no es un problema de movimiento. La forma de un frame de NAIF no aguanta 13-16 frames.

**SEQ: ¿la cadena secuencial antigua conserva el detalle?** (`SEQ_battery.log`, `SEQ_FACE/HAND73/BACK_FEET.png`; runs de septiembre, mismo registro de cámaras, sin PPISP)

| Run | HP 52 / 60 / 66 / 73 / 76 | Vibración |
|---|---|---|
| KB_K2 | 14,22 / 13,96 / 12,43 / 10,92 / 11,83 | 8,46 mm |
| L1 (escala bloqueada) | 14,48 / 14,49 / 12,84 / 11,51 / 12,38 | 8,67 mm |
| S2 (suavizado de posición cada 20) | 15,39 / 14,79 / 14,62 / 13,56 / 13,26 | 0,53 mm |

- KB_K2 está numéricamente cerca de NAIF, pero **vibra 8 mm**: inservible para el códec.
- A ojo, en el 73 TP1 es más nítido que KB_K2 y L1 (la métrica y el ojo no coinciden), y S2 es blando.
- **Conclusión:** la cadena conserva el detalle solo mientras vibra. El suavizado que la hace usable lo borra.

**FP/FT: podar las capas tenues de TP2** (`faint_prune.py`, `FP_battery.log`, `FT_battery.log`)

| Run | Qué es | VGSEditor | HP 66 / 73 / 76 | Luz | Recortes |
|---|---|---|---|---|---|
| FP05 | Ocultar registros con alfa pico < 0,05 | 47,7 MB | — / 12,31 / — | ≈ TP2 | ≈ TP2 |
| FP10 | Ídem < 0,1 | 38,4 MB | 15,89 / 14,21 / 14,85 | 1,00 | Cara del 73 moteada |
| FT10 | FP10 reentrenado 6000 pasos (708k registros) | 39,0 MB | 15,21 / 13,34 / 13,95 | **0,94** | Pelo más blando que TP2 |

- El criterio fijado de antemano era ≤ 45 MB y HP ≤ 14,36 / 12,05 / 12,95. **Ninguno lo cumple.**
- **Conclusión:** el detalle de TP2 vive en sus ~470k registros tenues apilados. En esa representación tamaño y detalle van atados, y quitarlos después se lleva el detalle.

### 8.10 Por qué hemos fallado (diagnóstico, 2026-11-15/19)

1. **Todo fue "semilla + pulido".** La población salía de otro sitio (cadena RM0, NAIF60, NAIF cada 3 frames) y luego se refinaba. El resultado siempre acabó en el detalle de su semilla (ST5-ST11, MS, TP0). En estático, el detalle lo crea la reestructuración, no el refinado: un frame recoloca ~414k splats.
2. **La recolocación nunca funcionó junto con una forma entrenable:**
   - Con opacidad por frame (cadena, JT, ST6), "muerto" exige estar apagado en todos los frames, y casi nada muere.
   - Cuando se desbloqueó (ST7-ST9), la forma estaba congelada y el clon era idéntico: salieron rayas fuera del rig.
3. **Transportamos soluciones de un solo frame** (NAIF), que no persisten.
4. **Lectura equivocada de Gracia:**
   - Gracia logra detalle de nivel NAIF con 249-285k registros por chunk, el 60-85 % de chunk entero. ST7L tiene 472k y es más blando.
   - La conclusión de ST10 ("más detalle = más registros") era falsa y llevó a TP1/TP2 y a la poda.
5. **Lo que no era el problema:**
   - **El presupuesto de entrenamiento.** Nuestros 20k pasos × 4 vistas son ~2.500 renders por frame; TRiGS usa ~2.000.
   - **El movimiento de la semilla** (flujo, MS).
6. **Lo que enseñan TRiGS y open4dgs** (§10):
   - La opacidad es un escalar × campana temporal, y una regularización 4D empuja lo inútil a morir. "Muerto" es global, así que la recolocación nunca se queda sin sitio.
   - La escala se entrena, con regularización de tamaño y tope de anisotropía (en su código, contra las "agujas" que se ven como rayas).
   - El clon reparte opacidad y escala con la fuente al estilo MCMC, sin saltos, y hereda su ventana.
   - Su modo PLY convierte justo PLYs estáticos por frame, como los nuestros, en 4D.
   - Su pérdida de alfa fuera de la máscara causa la transparencia que reconocen; **no se adopta** (regla del dueño).

---

## 9. Hacia dónde vamos

### 9.1 Vía J: reconstrucción conjunta del chunk (aprobada 2026-11-19; J1a/J1c y TRiGS T1 probados, ninguno cumple)

Diseño propio con ideas de TRiGS y open4dgs (nada de código copiado). Se implementa sobre el motor spacetime actual (`EngineSpacetime.*`, `TrainerSpacetime.cpp`).

1. **Registro:**
   - Spline de posición (K16) y de rotación (K8), como ahora; ya es compatible con VGS.
   - Color K8, como ahora.
   - **Opacidad = escalar base × ventana temporal aprendible** (centro μ_t, log-duración σ_t), en lugar de la spline de opacidad.
   - **Escala y SH constantes pero entrenadas**, con gradiente sumado sobre lotes de varios frames.
2. **Semilla:**
   - NAIF del chunk cada 3 frames: posición, color y forma.
   - Velocidad de nuestro flujo multivista.
   - σ_t por fila según la aceleración (σ = √(2·k·radio/|a|)): el movimiento uniforme vive mucho y los cambios de dirección poco.
   - Deduplicación de las filas lentas entre keyframes (probabilidad de quedarse = redundancia·Δ/alcance).
   - Presupuesto de ~300k registros, como Gracia.
3. **Pérdidas:**
   - L1 + SSIM;
   - **regularización 4D de opacidad** 0,01·mean(α·γ(t)), con γ desacoplado del gradiente;
   - **regularización de escala** 0,01·mean(exp(s)) con **tope de anisotropía**;
   - curvatura del movimiento;
   - nuestra coherencia afín;
   - consistencia profundidad-normal (contra la falsa transparencia);
   - habitación congelada;
   - nunca alfa fuera de la máscara.
4. **Recolocación cada 100 pasos, desde el paso 1.000 hasta el 83 %:**
   - Muerto si α < 0,005.
   - Puntuación = α + velocidad × vida dentro del chunk + gradiente 2D por vista visible + |dL/dμ_t| por visita.
   - Reparto MCMC de opacidad y escala entre la fuente y sus clones.
   - El clon hereda la ventana, con μ_t ± 0,25σ, y la trayectoria realineada a la nueva fase.
5. **Presupuesto:** ~80k renders por chunk, como ahora (~30 min).
6. **Exportación a VGS:** la vida del registro es donde α·γ > 1/255; la opacidad por frame es α·γ(t).
7. **Prueba J1, frames 45-76.** Criterio fijado de antemano, contra TP2M (TP2 rehecho con `bin_merge`):
   - error HP en 66/73/76 ≤ TP2M;
   - ≤ 45 MB en VGSEditor;
   - vibración ≤ 0,5 mm;
   - luz entre 0,98 y 1,02;
   - recortes de cara, mano y espalda sin rayas en cámaras no usadas en el entrenamiento.

   Si falla, la línea se deja.
8. **Orden de prueba (2026-11-19):**
   - **J1a**, la mecánica sobre una semilla existente (`battery_J1A.ps1`, binaria `bin_j1`):
     - semilla de FT10 (`FP10_clean`, 708k registros);
     - escala y SH entrenables (parche de ST10 reaplicado);
     - `--spacetime-relocate 0.01 --spacetime-relocate-every 100`;
     - receta de TP2, 20k pasos.
     - Criterio: ≤ 45 MB y HP 66/73/76 ≤ TP2M + 3 %, cara del 73 sin moteado, luz 0,98-1,02 y vibración ≤ 0,5 mm.
   - **J1b**, la semilla multi-keyframe, solo si J1a funciona.
   - **Resultado (2026-11-19)**, con el control TP2M (TP2 con `bin_merge`: HP 14,08 / 11,83 / 12,70, 59,6 MB, luz 1,03; el merge no cambió nada):
     - **J1a** (reg 0,01):
       - 41,3 MB, HP 14,53 / 12,48 / 13,27, luz 0,95, vibración 0,32 mm.
       - Cara sin moteado, mano como TP2M, pelo algo más blando.
       - Pero la recolocación se quedó sin sitio: movió 13k registros en 200 eventos.
       - La forma entrenable sola cierra ~60 % del hueco FT10→TP2M.
     - **J1c** (reg 0,03):
       - Recolocación activa (71k registros), pero HP 14,58 / 12,60 / 13,41 y 41,6 MB.
       - Recortes iguales que J1a: **reciclar con forma entrenable no añade detalle**.
     - Ninguno cumple el criterio. La bajada de luz a 0,94-0,95 viene de la semilla podada FP10 (FT10 igual).
     - El parche de forma entrenable está sin commitear en el árbol (binaria `bin_j1`).
9. **Segunda iteración opcional:** supervisión extra con renders de NAIF desde cámaras virtuales fuera del rig (como el modo PLY de TRiGS, que entrena contra renders de los PLY). Ataca las rayas fuera del rig, pero mete el parpadeo de NAIF.
10. **TRiGS ejecutado tal cual, T1 (2026-11-20).** Repo `D:\Dependencias\open4dgs-trigs-main`, AGPL, solo para evaluar; nada de su código entra en spirula.
    - **Modo:** PLY (`trigs.cli.train_from_plys`, que por debajo usa el entrenador "upstream" de TriGSVanilla).
      - Entrada: los NAIF 45-76.
      - Supervisión: renders de esos PLY desde cámaras sintéticas en órbita.
    - **Entorno:** venv de `ref4d` (torch 2.10 cu128, gsplat 1.5.3), más `gsply` y `splines` por pip, y `trigs` instalado editable sin dependencias.
      - `pytorch3d` no se compiló. En `ref4d\venv\Lib\site-packages\pytorch3d\` hay un sustituto propio: `knn_points` con KD-tree de scipy, y `sample_farthest_points` cambiado por un subconjunto aleatorio.
    - **Arnés `outputs\tc\run_trigs_ply.py`:** no modifica su código y da el mismo resultado. Dos ajustes:
      - la inicialización de anclas va en bloques de 256 filas en lugar de 2048, porque con 2048 desbordaba los 12 GB;
      - el grado SH del render se limita al de los datos. Su calentamiento lo sube a 3 aunque nuestros PLY son de grado 1, y fallaba en el paso 2000.
    - **Entrada recortada** a la caja del sujeto (`trigs_crop_inputs.py` → `outputs\tc\TRIGS_in`).
      - Los flotantes de NAIF a cientos de metros daban `scene_extent` = 740 m, y las cámaras en órbita veían a la persona diminuta.
      - La primera ejecución, con esos flotantes, se descartó.
    - **Receta:**
      - 800k primitivas, keyframe cada 3, 12.000 pasos (8 min).
      - 40 cámaras de 1024². Su caché de referencias vive en la GPU, y 120 cámaras necesitarían 16 GB.
      - PSNR de entrenamiento contra los renders de NAIF: 41,5.
    - **Resultado** con nuestras cámaras reales contra el vídeo (`TRIGS_T1_battery.log`, `TRIGS_T1_FACE.png`, `TRIGS_T1_HAND73.png`):

      | Run | HP 52 / 60 / 66 / 73 / 76 | Luz |
      |---|---|---|
      | NAIF | 14,02 / 13,73 / 11,98 / 10,18 / 11,16 | 0,99 |
      | TP2M | 15,06 / 14,87 / 14,08 / 11,83 / 12,70 | 1,03 |
      | ST7L | 16,05 / 15,96 / 16,32 / 15,18 / 14,57 | 1,03 |
      | **TRIGS_T1** | 16,89 / 15,97 / 15,16 / 15,20 / 15,62 | 0,98-0,99 |

      - Peor que ST7L en 52, 73 y 76.
      - Cara del 73 borrosa y con fantasmas.
      - La luz es buena porque copia la de NAIF.
      - Sus frames exportados quitan las filas invisibles, así que el número de filas cambia por frame. Por eso no se midieron tamaño `.vgs` ni vibración.
    - **Matiz:** prueba su modo PLY en esta GPU, no TRiGS con imágenes reales. En la órbita sintética la cara ocupa ~100 px y la supervisión de detalle es pobre.
    - **T2**, modo COLMAP con las imágenes del rig y un NPZ de inicio nuestro, **no se ha hecho**.

11. **TRiGS con imágenes reales: T2, T2b, T2c (2026-11-20/22).** Modo COLMAP de `open4dgs-trigs` sin modificar.
    - **Preparación (`outputs\tc\trigs_t2_prep.py`):**
      - `TRIGS_T2_data`: COLMAP del frame 45, más imágenes y máscaras de 45-76 como enlaces duros.
      - NPZ propio: centros de NAIF cada 3 frames (150k por keyframe), velocidad y aceleración de los 4 registros de ST7L más cercanos, tiempos y duraciones normalizados.
      - Con un tercer argumento, añade nuestra `room.ply` como filas `is_static`.
    - **Arnés `run_trigs_ply.py colmap`:**
      - caché de imágenes de 1500 vistas (fija a 300 en su código);
      - `TRIGS_MAX_SH` para cambiar el grado SH, fijo a 3 en su camino NPZ.
    - **Receta común:** 8 cámaras por paso, 12k pasos, 800k primitivas.
    - **Exportación:** con todas las filas (`--no-apply-temporal-cull --active-opacity-thresh -1`). Después, `trigs_frames_subject.py` quita las filas estáticas y reordena al formato 3DGS.

    | Run | Qué cambia | VGSEditor | HP 52 / 60 / 66 / 73 / 76 | Máscara 73 | Luz | Vibración |
    |---|---|---|---|---|---|---|
    | TP2M | (control) | 59,6 MB | 15,06 / 14,87 / 14,08 / 11,83 / 12,70 | 5,91 | 1,03 | 0,30 mm |
    | T2 | solo sujeto en el NPZ | — | 13,38 / 13,67 / 12,81 / 11,98 / 12,82 | 6,78 | 1,01 | — |
    | T2b (sin habitación al exportar) | + habitación estática, SH3 | 52,2 MB | 13,63 / 13,28 / 12,29 / 10,94 / 11,70 | 5,18 | 0,98 | 0,24 mm |
    | T2b recortado a SH1 sin reentrenar | — | 41,2 MB | 15,10 / 14,90 / 13,80 / 12,47 / 13,19 | 6,27 | 0,99 | — |
    | **T2c** | **SH1 entrenado** | **41,2 MB** | **14,70 / 14,36 / 13,42 / 11,81 / 12,64** | **5,66** | 0,97-0,99 | **0,21 mm** |

    - **T2:** rayas blancas (el poste de la habitación) atraviesan al sujeto. Sin filas estáticas, los splats del sujeto explican el fondo.
    - **T2b:** limpio; detalle al nivel de NAIF. Pasa de tamaño por el SH3.
    - **T2c cumple el criterio completo** (≤ 45 MB, HP ≤ TP2M + 3 %, máscara ≤ TP2M):
      - es el primer resultado entregable;
      - cara y mano limpias, al nivel de TP2M;
      - 724k registros, el 15 % de chunk entero.
    - **Pendientes:**
      - humo en el suelo bajo los pies (también en TP2M y J1a);
      - ~2 h por chunk aquí, limitado por cargar los PNG (GPU al ~55 %);
      - el código es AGPL, así que para producción hay que reimplementarlo como diseño propio en spirula;
      - falta probarlo en otros chunks y otra toma.

### 9.2 Caminos anteriores, con su estado

| Camino (lista del 2026-11-03) | Estado |
|---|---|
| Analizar los registros de Gracia | Hecho en parte (estructura, SH temporales, churn). Sigue siendo útil para la métrica por región |
| Partir del estático nítido (NAIF) con correspondencias | Probado como transplante (TP) y como semilla NAIF60 (MS). La correspondencia directa no existe (0,4-1,5 %). Lo recoge J en forma de semilla multi-keyframe con forma reentrenada |
| `PLAN.md` paso 3 "mover primero" y paso 4 más resolución de movimiento | Descartado: MS mostró que el movimiento no es el límite |
| Métrica de detalle por región | Pendiente. El error HP en píxeles malos de ST7L es lo usado hasta ahora; siempre junto con recortes |
| Bug de `--temporal-birth-dir auto` que ignora un `--temporal-warp-dir` de fichero | Pendiente, menor |

---

## 10. Papers

**Colección principal:** `D:\Dependencias\4DGS_Papers\`.

| Ruta | Contenido |
|---|---|
| `README.md` | Índice de los ~373 papers por relevancia (3 = ataca el problema, 2 = mecanismo útil, 1 = tangencial, 0 = ajeno; `plantilla` = SMPL/huesos, descartado) |
| `pdf\` | 374 PDF, `<arXiv id>_<título>.pdf` |
| `txt\` | Texto extraído de cada PDF |
| `metadata.json` | Título, autores, abstract, código |
| `_notes\pass1_all.json` | Primera lectura de cada paper |
| `_notes\deep\<id>.md` | Lectura a fondo de ~110 papers |
| `_notes\deep\grupo_A.md` … `grupo_L.md` | Síntesis por tema: A flujo→movimiento por splat; B jerarquía movimiento/apariencia en humanos; C streaming y keyframes; D códecs con identidades persistentes; E-F compresión; G-H multivista dinámico; I-J monocular; … |
| `_notes\deep\PLAN.md` | Plan de investigación y diseño del entrenador 4D nativo |
| `_lists\` | Listas de origen (qianx77 Awesome-4DGS, awesome-4dgs, enlaces del dueño + gaussian-splatting-daily) |

**Repos leídos el 2026-11-19** (base de la vía J; solo ideas):

| Repo | Licencia | Qué aporta |
|---|---|---|
| `D:\Dependencias\open4dgs-core-main` | MIT | Preparación: RoMa v2 multivista + seguimiento MEMFOF → posición, velocidad y aceleración por punto cada 5 frames; subkeyframes de vida 1 frame para lo rápido; presupuesto que nunca aclara lo que se mueve; cadenas largas con comprobación de ciclo; reparación rígida por clúster. Exportación `.trigsbin`. Medida suya: la nitidez sube con los splats vivos por frame hasta el techo de un frame solo |
| `D:\Dependencias\open4dgs-trigs-main` | AGPL-3.0 | Entrenador TRiGS: ventana temporal por splat, regularización 4D de opacidad, regularización de escala con tope de anisotropía, recolocación (`strategy/motion_guided_relocation.py`) con reparto MCMC y ventana heredada, σ_t inicial por aceleración, modo PLY (`cli/train_from_plys.py`, `init/from_plys.py`) |

Resumen de valores en la memoria `open4dgs-core-reference.md`. Nota del paper TRiGS: `_notes\deep\2604.00538.md`.

**Otras carpetas** (solo ideas, nunca código):

- `C:\Users\Victor\Downloads\queen-main\` (QUEEN, licencia no comercial).
- `...\queen-main\more papers\` y `...\queen-main\compressionpapers\`.

**Los que más han pesado** (números vía resumen: comprobar en el PDF antes de usarlos):

| Paper (arXiv) | Qué aporta |
|---|---|
| FreeTimeGS 2506.05348 / FreeTimeGS++ 2605.03337 | Movimiento analítico, opacidad temporal suave; split que conserva la contribución. Base de la representación spacetime. |
| STG (Spacetime Gaussians) | Trayectoria polinómica → nuestros B-splines |
| Mobile-4DGS 2610.05289 (sin licencia) | Compuerta estático/dinámico, regularizadores de aceleración y extensión, ventana de opacidad |
| TrackerSplat 2604.02586 (Apache-2.0) | Diagnóstico: un splat desplazado más que su huella se recolorea o se apaga en vez de moverse (nuestro síntoma del pelo); movimiento desde tracks densos triangulados |
| HiFi4G 2312.03461 | Peso de apariencia adaptativo w = exp(−50·\|dp\|²) |
| ReCon-GS 2509.24325, 4DGCPro 2509.17513, CDGS 2602.03538, TED-4DGS 2512.05446 | Movimiento por anclas, penalización de tasa, presupuesto diferenciable de registros, ventana de vida aprendible |
| Eyeline 2511.21697 | Movimiento polinómico por segmentos con escala y SH constantes (= nuestro modelo de códec); rejillas de exposición por píxel |
| TaoGS 2509.07653, EvolvingGS 2503.05162, Director 2604.01678, MoRGS 2603.25042, IGS 2503.16979, V3 2409.13648 | Selección para el pelo con ids persistentes (ver `README.md` y las notas `deep`) |
| TRiGS 2604.00538, SharpTimeGS 2602.02989 | Rigidez por kNN; opacidad de techo plano con rampas |
| GaussiAnimate 2604.08547 | Gaussianas canónicas + deformación entrenadas juntas; ARAP (los huesos no aplican) |
| Dynamic 3D Gaussians | Rigidez local entre vecinos (origen de la idea de coherencia) |

---

## 11. Cómo reproducir lo último

```powershell
# ST7L (base estable) con el binario actual; las salidas van a outputs\tc\ST1 (renombrar)
$env:ST_EXE = "D:\Dependencias\spirula-studio\outputs\tc\bin_st\spirula.exe"
$env:ST_ITERS = "20000"
$env:ST_EXTRA = ""   # ST7L; para ST7: "--opacity-reg 0.01 --spacetime-relocate 0.01 --spacetime-relocate-every 100 --spacetime-spare 0.1 --cap-max 700000"
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Dependencias\spirula-studio\outputs\tc\battery_ST.ps1
```

- `battery_ST11.ps1` es el modelo de batería completa: entrena, renombra, limpia con `subject_filter --hide` en `<run>_clean`, y pasa `det_eval2`, `vib_runs`, `fade_drift`, `hand_views` y `face_crop`.
- Tarda ~22 min por run de 20k pasos.
- Se lanza desacoplado. El resumen va a `<BATERÍA>_battery.log`.

**Con la binaria del merge (desde 2026-11-19):**

- La prueba de humo es `outputs\tc\smoke_merge.ps1`: receta de TP2, 300 pasos, sobre `TP2_clean`.
- Para la receta completa de TP2 (20k pasos) con `bin_merge`, la plantilla es `battery_TP2.ps1`: hay que cambiar la binaria y el nombre del run.
- La evaluación completa (limpieza, `vgsplyseq`, VGSEditor, `transplant_eval`, `hand_views`, `back_feet_sheet`, `floor_dirt`, `vib_runs`) está en `battery_FT.ps1`.
- `back_feet_sheet.py` falla en el frame 76 (caja vacía): usar 45 52 66 73.

**TRiGS T1** (venv de `ref4d`, desde `%TEMP%`):

```powershell
python outputs\tc\trigs_crop_inputs.py C:\Users\Victor\AppData\Local\Temp\trigs_in outputs\tc\TRIGS_in 45 76
D:\Dependencias\ref4d\venv\Scripts\python.exe -I -u -X utf8 outputs\tc\run_trigs_ply.py --input-dir outputs\tc\TRIGS_in --output-dir outputs\tc\TRIGS_T1 --config.keyframe-stride 3 --config.fps 30 --config.n-steps 12000 --config.target-count 800000 --camera.width 1024 --camera.height 1024 --camera.longitude-steps 8 --camera.latitude-steps 5 --no-render-debug
powershell -File outputs\tc\battery_TRIGS_eval.ps1
```

- `trigs_in` son enlaces duros a los NAIF de `C:\Users\Victor\Documents\Gracia4DGSConverter\VIDEOTIKI\output`.
- Las rutas de `outputs\tc` son relativas a `D:\Dependencias\spirula-studio`; en la ejecución real se pasaron absolutas.
