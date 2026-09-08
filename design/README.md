# design/

Todo lo que hace falta para implementar la interfaz de Miku sin volver a abrir Figma.

La **verdad canónica** es el archivo de Figma; esto es su exportación. Si algo no cuadra,
gana Figma y hay que regenerar esta carpeta.

| | |
|---|---|
| **Documento del sistema** | [`../DISENO.md`](../DISENO.md) — dirección, reglas, historial de decisiones, citas de la HIG, trampas de Figma, notas de SwiftUI |
| **Tokens** | [`tokens.json`](tokens.json) — 18 colores × 2 modos, espaciado, radios, 4 efectos, 9 estilos de texto |
| **Figma** | `PTGknf2i1QWTJwrhAYpdt3` · archivo **Miku-LLM** |

## pantallas/

Todas las pantallas terminadas del producto, exportadas a 1× (tamaño real en puntos),
cada una en sus dos temas.

| Archivo | Superficie | Medidas | Vigencia |
|---|---|---|---|
| `consola-inicio-*` | Consola · Inicio — la portada | 1240 × 800 | v2, actual |
| `consola-conversacion-*` | Consola · Conversación | 1240 × 800 | v2, actual |
| `consola-notas-*` | Consola · Notas | 1240 × 800 | v2, actual |
| `consola-actividad-*` | Consola · Actividad | 1240 × 800 | v2, actual |
| `ajustes-claves-*` | Ajustes · Claves y conexiones | 820 × 560 | v6, actual — sidebar y tipografía nuevos |
| `ajustes-ia-*` | Ajustes · IA | 720 × 520 | **v1** — sidebar denso, sin actualizar (ver aviso abajo) |
| `avatar-flotante-*` | Avatar flotante, sobre un escritorio | ventana 320 × 440 | v2, actual |

⚠️ **`ajustes-ia-*` no pasó por el rediseño del sidebar (v5) ni por el cambio tipográfico
(v7).** Es la única sección de Ajustes con contenido real además de Claves, así que se
incluye porque hace falta, pero **antes de implementarla hay que rehacer su sidebar** con
el lenguaje de losa flotante de `ajustes-claves-*` — ver `DISENO.md` §9.6 y §18.

## referencia/

Material de apoyo: paleta, tipografía, estados, y piezas que aún no son pantallas propias.

| Archivo | Qué es |
|---|---|
| `fundamentos-oscuro.png` / `fundamentos-claro.png` | Paleta completa, espécimen tipográfico, métrica, aviso de contraste |
| `estados-de-miku.png` | Los seis estados de la barra de menú y su silueta |
| `menu-del-perfil.png` | Menú que abre el avatar del riel |
| `opciones-de-vista.png` | Popover que personaliza la portada |
| `ciclo-vida-credencial-*` | Los siete estados de una credencial (vacía → sellada → revocada), usado dentro de Claves |
| `inicio-reacciona-estados.png` | Cómo cambian el aura y la cápsula en Reposo/Pensando/Hablando/Silenciada |

## Lo que NO está aquí (a propósito)

- **`Page 1`** — la exploración original en Figma. Nunca fue parte del sistema; no se exporta.
- **`v1 · Consola densa`** — versión rechazada, marcada «no usar» dentro de Figma. Documentada
  en `DISENO.md` §3 sólo como historial, no exportada como imagen.
- **El set de componentes `Indicador de estado`** en sí (variantes de Figma) — su contenido
  visual ya está cubierto por `estados-de-miku.png`; el componente vive sólo en Figma porque
  no tiene equivalente útil como imagen suelta.
- Los mockups de contexto en MacBook (capturas de presentación) — no aportan nada que
  `consola-inicio-*` no tenga ya a tamaño real.

## Antes de escribir la primera vista

1. **Lee `../DISENO.md` §11 (reglas duras).** Son once y ninguna es negociable.
2. **Empaqueta las fuentes.** Geist e IBM Plex Mono, ambas open source. Al no usar SF Pro
   hay que replicar a mano el escalado de texto accesible.
3. **Los colores van como `Color` semántico** con variantes claro/oscuro, conservando los
   nombres del sistema (`fondo/vidrio`, `acento/tinta`…) para que diseño y código hablen igual.
4. **Los iconos del diseño están nombrados con su SF Symbol** (lista en `DISENO.md` §17).
   Usa el símbolo real, no el dibujo del mockup.
5. **El anillo graduado es un medidor real** del nivel de entrada del micrófono, no adorno.
6. **`ajustes-ia-*` necesita su sidebar rehecho** antes de implementarse — ver el aviso arriba.

## Falta por diseñar (no existe ni como PNG)

Vista **Transcripciones** · **primer arranque** · ventana de **confirmación** como pantalla
propia · estado *hover* del avatar · secciones General/Voz/Permisos/Avanzado de Ajustes
(Voz existe sólo en el código de M3, sin pasar por Figma).

Bloqueado: **Miku con los ojos cerrados** — hay que reexportar el modelo 3D en esa pose.
