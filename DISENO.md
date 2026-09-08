# Sistema de diseño de Miku

> Documento canónico de la interfaz. Recoge la dirección visual, los tokens, las reglas
> y —sobre todo— **por qué** cada decisión está tomada, incluido lo que se probó y se
> descartó. Si retomas el proyecto sin contexto, lee esto antes de tocar Figma o SwiftUI.
>
> Archivo Figma: **Miku-LLM** · `PTGknf2i1QWTJwrhAYpdt3`
> Complementa a `CLAUDE.md` (código) y al spec de contenido de M3.5.
> Última pasada: v7 (tipografía).

---

## 0. Cómo usar este documento

- **§2 y §3** son lo más importante. La dirección y el historial de rechazos son lo que evita
  repetir errores ya cometidos. Si vas con prisa, lee sólo eso.
- **§4–§8** son el sistema: tokens, tipografía, métrica, materiales. Son datos verificados
  contra el archivo real, no de memoria.
- **§11** son las reglas que no se negocian. Si una propuesta nueva las rompe, la propuesta
  está mal, no la regla.
- **§16** son trampas concretas de la API de Figma que ya costaron tiempo. No las redescubras.

---

## 1. Qué es Miku

Asistente de voz personal para macOS, con la persona de Hatsune Miku. Se activa diciendo
«Miku», escucha por micrófono, responde hablando, controla el Mac (abrir apps, volumen,
comandos) y **transcribe lo que se habla alrededor** (clases, reuniones) convirtiéndolo en notas.

Lo que esto implica para el diseño:

| Hecho del producto | Consecuencia de diseño |
|---|---|
| Corre **local por defecto** (Ollama/qwen), sin internet ni coste | La nube es la excepción, no el camino feliz. Nada de upsell agresivo. |
| **No hay cuenta**; nada sale del Mac | No existe «cerrar sesión», ni perfil en la nube, ni sincronización. |
| Es **de voz primero** | La interfaz es sobre todo un espejo del estado, no un formulario. |
| Puede **actuar sobre el Mac** | La confirmación de acciones es la pieza de seguridad del producto. |
| Escucha **la sala**, no sólo al usuario | El copy nunca dice «lo que tú dices». Neutro sobre quién habla. |
| Es una **IA que se equivoca** | Transparencia explícita: los turnos van etiquetados y las herramientas que llamó se muestran. |

---

## 2. La dirección: «Vidrio y vacío»

**Futurista por lo que quita, no por lo que añade.**

Miku es la única fuente de luz de la pantalla — un aura turquesa detrás de ella. Todo lo demás
es vidrio flotando en la oscuridad. La textura técnica viene de **una sola familia monoespaciada
en micro-etiquetas** y de **un único acento**. Nunca de neón, retículas de colores ni marcadores
circulares tipo HUD de videojuego.

La tensión del encargo original era «futurista» contra «Apple»: lo futurista de las referencias
(collages técnicos, kits de HUD) suma capas; Apple resta. Se resolvió restando.

### Los cuatro principios

1. **Un solo acento.** El turquesa `#39C5BB` significa «Miku está activa» o «esto es
   accionable». Nunca decora. Si algo no es accionable ni es estado, va en gris.
2. **La forma manda.** Cada estado tiene silueta propia. El color refuerza, nunca informa solo
   — en la barra de menú macOS pinta los iconos de plantilla en monocromo.
3. **El vidrio es para los controles.** Barras, paneles y cápsulas flotan sobre el contenido.
   Las tarjetas de contenido nunca llevan vidrio.
4. **El dato al servicio.** CPU y RAM existen, pero en 11 px y en gris, y fuera de la portada.
   Lo accionable manda sobre lo que sólo se mira.

### La filosofía operativa

> **Menos información, más espacio.**
> Cuando algo se sienta «sin valor», la respuesta es **jerarquía, no más texto**.

Esta frase resume la lección más cara de todo el proceso (§3). Un panel que se siente pobre
casi nunca mejora añadiendo etiquetas: mejora añadiendo niveles, o quitando ruido para que
lo que queda respire.

---

## 3. Historial de decisiones — qué se rechazó y por qué

Esta sección existe para no volver atrás. Cada versión se rechazó por una razón concreta.

### v1 — Consola densa · **RECHAZADA**
Dos columnas de tarjetas flanqueando a Miku, más una franja de telemetría. Todo el producto
en una sola pantalla.
**Por qué falló:** saturación. Ponía en la portada lo que Apple pondría un clic más allá.
**Vive en:** sección `v1 · Consola densa — sólo referencia, no usar`.

### v2 — Portada vacía + vistas propias · **ACEPTADA**
La portada sólo lleva: Miku, la cápsula de estado, el último intercambio, la confirmación
pendiente y unas pocas anotaciones mono en los bordes. Todo lo demás pasa a vistas con
navegación propia. La telemetría CPU/RAM baja a una línea dentro de Actividad.

### v3 — Capa de instrumento + sidebar rico · **PARCIAL**
Se añadió la capa de instrumento (§8): geometría fina monocroma detrás de Miku, para que el
vacío no se sintiera vacío. **Aceptada.**
El sidebar pasó a tener epígrafes de grupo, descripción bajo cada ítem, contadores y una
tarjeta de cerebro con párrafo. **Rechazado más tarde** (ver v5).

### v4 — Claves como tabla de base de datos · **RECHAZADA**
Tabla de 5 columnas (servicio, huella, estado, último uso, sparkline) más un panel de detalle
separado con 6 metadatos.
**Por qué falló:** el usuario pidió estética de base de datos y se entregó *densidad* de base
de datos. Unas 40 cadenas de texto en un panel de ajustes.

### v5 — Sidebar de dos losas · **ACEPTADA** ← la lección clave
El usuario dijo dos cosas que parecían contradecirse: *«muy saturado»* y *«el sidebar sigue
sintiéndose simple, sin valor»*.

No eran contradictorias. **El sidebar tenía ~20 cadenas de texto y aun así era una lista plana.**
La referencia que aportó tenía ~10 palabras y se sentía mucho más rica, porque su valor venía
de la **estructura**: riel de iconos + panel de rótulos + un ítem desplegable con conector.

El rediseño quitó epígrafes, descripciones, contadores múltiples y la tarjeta de cerebro
(que además duplicaba lo que ya estaba en el menú del perfil), y añadió el segundo nivel.
Resultado: **9 cadenas de texto**, y se siente más completo.

### v6 — Claves calmadas + dos bugs geométricos · **ACEPTADA**
Fuera la tabla y el panel de detalle. Ahora es una lista de servicios de una línea donde el
registro seleccionado **se despliega en línea**. De ~40 cadenas a ~18.
Además se corrigieron dos fallos reales que estaban **en ambos temas** aunque sólo se notaban
en oscuro (§16 explica cómo se diagnosticaron).

### v7 — Tipografía · **ACEPTADA**
SF Pro se sentía invisible por ser la nativa de Apple; JetBrains Mono, demasiado «de
programador». Cambio a **Geist + IBM Plex Mono** (§5).

---

## 4. Tokens de color

Colección **`Miku · Color`**, dos modos: `Oscuro` y `Claro`.
Cambiar de tema = cambiar el modo de la colección en el panel derecho de Figma. Las pantallas
claras son **clones con el modo puesto**, no diseños duplicados a mano.

| Token | Oscuro | Claro | Para qué |
|---|---|---|---|
| `fondo/lienzo` | `#0A0C0F` | `#EEF1F3` | Fondo de ventana |
| `fondo/lienzo-2` | `#12161A` | `#FFFFFF` | Fondo alterno / ventanas de ajustes v1 |
| `fondo/vidrio` | `#FFFFFF @6%` | `#FFFFFF @72%` | Superficie de vidrio |
| `fondo/vidrio-alto` | `#FFFFFF @10%` | `#FFFFFF @92%` | Vidrio más sólido (campos, chips) |
| `fondo/elevado` | `#1A1F24` | `#FFFFFF` | Popovers y menús |
| `fondo/atenuacion` | `#000000 @34%` | `#FFFFFF @58%` | **Capa de atenuación** bajo el vidrio |
| `linea/sutil` | `#FFFFFF @12%` | `#0B1416 @10%` | Filetes, separadores, instrumento |
| `linea/fuerte` | `#FFFFFF @22%` | `#0B1416 @20%` | Marcas mayores, escuadras |
| `texto/primario` | `#F4F7F8` | `#0E1417` | Texto por defecto |
| `texto/secundario` | `#A7B2B8` | `#55636A` | Apoyo |
| `texto/terciario` | `#757F85` | `#5F6D74` | Micro-etiquetas, metadatos |
| `texto/sobre-acento` | `#04211F` | `#04211F` | Texto sobre relleno turquesa |
| `acento/tinta` | `#39C5BB` | `#0F726C` | **Texto, icono o borde** en acento |
| `acento/relleno` | `#39C5BB` | `#39C5BB` | **Superficies y gráficos** en acento |
| `acento/velo` | `#39C5BB @16%` | `#39C5BB @18%` | Fondos teñidos suaves |
| `estado/exito` | `#30D158` | `#248A3D` | Válido, hecho |
| `estado/aviso` | `#FFD60A` | `#8A6100` | Requiere atención |
| `estado/peligro` | `#FF453A` | `#C4271C` | Error y destructivo |

### Por qué el acento son dos tokens y no uno

Medido: **`#39C5BB` sobre blanco da 2,15:1**, muy por debajo del mínimo de 4,5:1 para texto.
Por eso:

- `acento/relleno` (`#39C5BB` en ambos modos) → **sólo** superficies, rellenos y gráficos.
- `acento/tinta` (`#0F726C` en claro, **5,8:1**) → todo lo que sea texto, icono o borde.

En oscuro los dos pueden ser `#39C5BB` porque ahí da **9,1:1**.
**Si añades un acento nuevo, repite el desdoblamiento.**

### El rojo está reservado

`estado/peligro` es sólo error y destructivo. El punto de «grabando» usa el **acento**, no
rojo, para no colisionar con esa semántica. Es una aplicación directa de *«evita usar el mismo
color para significar cosas distintas»*.

---

## 5. Tipografía

**Geist para la interfaz · IBM Plex Mono para el instrumento.**

- **Geist** tiene altura de x alta y remates planos, así que aguanta 11 y 13 pt en la densidad
  de macOS sin volverse blanda. Es el sustrato de precisión.
- **IBM Plex Mono** lleva todo el carácter de archivo técnico, y va justo donde vive el
  carácter: micro-etiquetas, huellas, el reloj, la línea de redacción, las anotaciones del anillo.

Se descartaron: **Geist Mono** (coherente pero neutra, perdía el carácter) y el par
**Geist + Geist Mono** (es el look por defecto de las herramientas de IA ahora mismo —
cambiaría un genérico por otro más reciente).

| Estilo | Fuente | Tamaño/interlínea | Tracking | Caja | Uso |
|---|---|---|---|---|---|
| `Miku/Display` | Geist **Bold** | 34/40 | **−2 %** | — | Portadas |
| `Miku/Título 1` | Geist **Bold** | 22/27 | **−2 %** | — | Título de ventana o sección |
| `Miku/Título 2` | Geist **Bold** | 16/21 | **−1,5 %** | — | Estado en curso, títulos de tarjeta |
| `Miku/Cuerpo` | Geist Regular | 13/18 | −0,5 % | — | Texto por defecto |
| `Miku/Cuerpo énfasis` | Geist **SemiBold** | 13/18 | −0,5 % | — | Etiquetas de control, botones |
| `Miku/Secundario` | Geist Regular | 11/15 | 0 | — | Apoyo, notas al pie |
| `Miku/Etiqueta HUD` | IBM Plex Mono Medium | 11/14 | **+9 %** | MAY | Micro-etiquetas. **Nunca texto esencial** |
| `Miku/Dato` | IBM Plex Mono Medium | 15/19 | −1 % | — | Cifras en línea |
| `Miku/Dato grande` | IBM Plex Mono **SemiBold** | 28/32 | **−2 %** | — | Cifra protagonista |

### Reglas tipográficas

- **Salto de peso deliberado: 400 → 600 → 700.** Regular para leer, SemiBold para controles,
  Bold para títulos. Sin escala intermedia. Ese salto drástico es lo que da carácter editorial.
- **Tracking por regla, no por gusto:** todo lo que va en mayúsculas y es técnico lleva
  espaciado **amplio y positivo** (+9 %). Los títulos grandes llevan **negativo** (−2 %):
  apretarlos los hace compactos y modernos.
- **El tracking va en porcentaje**, no en píxeles, para que escale solo.
- **No se usa peso Light**, aunque encaje estéticamente. La guía de tipografía es explícita:
  evita Ultralight, Thin y Light, sobre todo en tamaños pequeños. Aquí el cuerpo vive a
  11–13 pt sobre vidrio oscuro, donde el texto claro y fino ya se atenúa ópticamente.
- **Suelo de tamaño en escritorio: 10 pt.** Las etiquetas HUD van a 11 para no rozarlo.

### Cifras tabulares

Deben estar activas en los estilos. **No se pueden escribir por la API de Figma** en esta
versión (§16) — hay que activarlas a mano en el panel de texto → tres puntos → *Details* →
*Tabular numbers*. Mitigación: casi todas las cifras del diseño ya viven en estilos
monoespaciados, que son tabulares por construcción. Sólo quedan sueltos los contadores del
sidebar.

---

## 6. Métrica

Colección **`Miku · Métrica`**, un solo modo.

| Espaciado | | Radios | |
|---|---|---|---|
| `espacio/xs` | 4 | `radio/sm` | 8 |
| `espacio/sm` | 8 | `radio/md` | 12 |
| `espacio/md` | 12 | `radio/lg` | 18 |
| `espacio/lg` | 16 | `radio/xl` | 26 |
| `espacio/xl` | 24 | `radio/completo` | 999 |
| `espacio/2xl` | 32 | | |
| `espacio/3xl` | 48 | | |

**Rejilla de 8.** Los radios crecen con la superficie: cuanto más grande el contenedor, más
redondo, para que la curva se lea igual de suave a cualquier tamaño.

Radios en uso: ventana 12 · losas flotantes 20 · paneles y tarjetas 12–14 · filas de
navegación 11 · botones 8–9 · cápsula de estado 28 · pastilla flotante 22.

---

## 7. Materiales

### Estilos de efecto

| Estilo | Qué es |
|---|---|
| `Miku/Vidrio (desenfoque)` | `BACKGROUND_BLUR` radio 32 |
| `Miku/Sombra panel · oscuro` | Sombra calibrada para fondo negro |
| `Miku/Sombra panel · claro` | Sombra calibrada para fondo claro |
| `Miku/Sombra flotante` | Sombra larga para elementos que flotan sobre el escritorio |

### Las reglas del vidrio

1. **El vidrio es la capa funcional.** Barras, losas de navegación, cápsulas y popovers.
   Las tarjetas de contenido **nunca** llevan vidrio.
2. **Vidrio sobre contenido necesita capa de atenuación.** Siempre dos rellenos:
   `fondo/atenuacion` **debajo** de `fondo/vidrio`. Sin ella, el cuerpo blanco de Miku se come
   el texto — pasó de verdad en el primer render de la cápsula y de la franja inferior.
3. **El contenido va a sangre por debajo del vidrio**, no empieza donde el panel acaba.
   Los controles flotan sobre el contenido, no en el mismo plano. Cuando el sidebar tapa parte
   del lienzo, Miku y el anillo **se recentran ópticamente**; la retícula no.
4. **Las sombras se recalibran por tema.** Están escritas a mano (no son variables), así que
   al clonar a claro hay que bajarlas: negro @34 % → `rgba(13,23,26,.10)`.

---

## 8. La capa de instrumento

Lo que llena el vacío de la portada sin volver a saturarla. **Geometría, no información.**
Si añades bloques de lectura con datos aquí, vuelves a v1.

Todo a 1 px, monocromo, con `linea/sutil` y `linea/fuerte`. **Sin acento**, con una excepción.

| Elemento | Geometría |
|---|---|
| Retícula | Líneas cada 40 pt en toda la ventana, opacidad 0,35 |
| Anillo graduado | R = 412, **96 marcas**, mayor cada 8 (13 px vs 6 px) |
| **Nivel de entrada** | Las primeras marcas encendidas **en acento** = nivel real del micrófono |
| Círculo interior | R = 296, trazo continuo, opacidad 0,5 |
| Anillo del núcleo | R = 186, punteado (24 segmentos alternos) |
| Radios | 8 tramos cortos, de R+26 a R+54 |
| Escuadras | Esquinas en (280,160) (960,160) (280,720) (960,720), brazo 26 — alineadas a la rejilla de 40 |
| Escala de sesión | Barra graduada 0–25 s bajo la anotación superior izquierda, con lo transcurrido en acento |

**La excepción del acento está justificada:** el anillo graduado *es* el medidor de nivel del
micrófono. Deja de ser adorno y pasa a ser el instrumento que aparenta ser.

Las guías con etiqueta se quitaron en v5 (eran texto suelto). **Se conservan las líneas guía y
sus puntos**, que son geometría pura.

La capa es **apagable** desde el popover «Opciones de vista» → *Instrumento de fondo*.
Centro del instrumento: `(620, 470)` en modo enfoque; desplazado **+158** cuando el sidebar
está abierto.

---

## 9. Las superficies

### 9.1 Consola — ventana 1240 × 800, radio 12

Cinco destinos: **Inicio · Conversación · Transcripciones · Notas · Actividad**.

**Inicio (la portada).** Sólo lo que importa *ahora*:
- Miku al centro con su aura y el instrumento detrás
- La **cápsula de estado** flotando sobre su cuerpo (y = 640): indicador de forma + estado +
  temporizador de sesión + onda en vivo
- El **último intercambio** (dos líneas) en el borde izquierdo, a media altura
- La **confirmación pendiente**, si la hay, en el borde derecho a la misma altura
- Dos anotaciones mono en las esquinas y cuatro cruces de registro

**Conversación.** El transcript toma el escenario y **Miku se reduce a un retrato de 64 pt**
con su anillo de estado arriba a la derecha. Turnos etiquetados `TÚ` / `MIKU` y **chips con la
herramienta que llamó de verdad** — ese es el mecanismo de transparencia sobre la IA.
Abajo, entrada de texto siempre presente como alternativa a la voz.

**Notas.** Lista sin tarjetas. La escucha en curso es **una línea** con «Terminar y guardar»,
no un bloque.

**Actividad.** Registro de acciones sobre el Mac. **Aquí vive la telemetría**: una sola línea
con cerebro, oído, turno, CPU y RAM. Nunca en la portada.

**Transcripciones.** *Sin diseñar todavía.*

### 9.2 El sidebar — dos losas flotantes

La pieza que más iteró. Estructura final:

```
┌──────┐ ┌────────────────┐
│ ◉    │ │ ◉  Miku        │   Riel  x=16 y=48  60×736  r20
│ ──── │ │ ───────────────│   Menú  x=84 y=48 216×736  r20
│ ⌂ ●  │ │ ⌂  Inicio      │   separación 8 pt
│ ▭    │ │ ▭  Conversación│   empiezan en y=48: el semáforo va sobre la ventana
│ ∿    │ │ ∿  Transcripc. │
│ ▤    │ │ ▤  Notas       │   ← desplegada
│ ◷ ▲  │ │   │ ▤ Clase…   │      conector vertical en x=31
│      │ │   │ ▤ Reunión… │      hijos indentados a x=48, alto 30, paso 34
│  │   │ │ ◷  Actividad ①│   ← única insignia de todo el sidebar
│  │   │ │                │
│ (Y)  │ │                │   avatar al pie del riel → menú de perfil
└──────┘ └────────────────┘
```

- **Riel:** sólo iconos de 20 pt en ranuras de 40×40 (radio 12), paso 48. Es el estado
  plegado del sidebar. Al pie, el avatar del perfil.
- **Menú:** cabecera + filete + filas de 38 pt (radio 11), paso 44. Icono a x=11, rótulo a x=43.
- **Seleccionado = píldora sólida de acento** con texto oscuro, en riel y en menú.
  Es la convención de macOS (Finder y Mail rellenan la fila seleccionada con el color de
  acento) y da el ancla fuerte que la lista necesitaba. **No choca** con «el acento significa
  Miku activa» porque los estados de Miku se distinguen por forma, nunca por color solo.
- **Sin epígrafes de grupo. Sin descripciones. Una sola insignia.**
- La región de navegación acaba en **x = 300**; el contenido empieza en **x ≈ 332**.

**Lo que NO va en el sidebar** (y por qué): la tarjeta de cerebro y la lista de utilidades
—claves, permisos, ayuda— vivían aquí y se quitaron: **ya están en el menú del perfil**,
al pie del riel. Era duplicación.

### 9.3 Menú del perfil

Se abre desde el avatar. Cabecera con «Perfil local · nada sale de este Mac», y luego:
Perfil de Miku · Preferencias… `⌘,` · Claves y conexiones… · Permisos del sistema… ·
Notificaciones · Buscar actualizaciones · Salir de Miku `⌘Q`.

**No lleva «Cerrar sesión»** — Miku es local y no hay cuenta que cerrar. La guía es explícita:
pide crear una cuenta sólo si tu funcionalidad principal la necesita.

### 9.4 Opciones de vista (popover)

Único botón de la barra de herramientas de la Consola. Personaliza la portada:
interruptores para *Último intercambio*, *Confirmaciones pendientes*, *Anotaciones de borde*,
*Instrumento de fondo*, *Motor y escucha*; segmentados para *Tamaño de Miku* y
*Cápsula de estado*; y «Restablecer portada».

**No lleva selector de claro/oscuro**: un ajuste de apariencia propio de la app confunde,
porque la gente espera que respete el del sistema.

**Por qué es un popover y no Ajustes:** lo que muestra u oculta partes de la vista actual va
en esa vista, no en la ventana de ajustes. Y por eso tampoco hay botón «Ajustes» en la barra
de herramientas — vive en el menú de la app y en `⌘,`.

### 9.5 Avatar flotante — ventana 320 × 440, sin borde

Miku sobre el escritorio, con sombra de contacto elíptica (no sombra de caja: el render es una
imagen con transparencia y una sombra normal dibuja el rectángulo). Debajo, **pastilla de
estado** de vidrio *clear* con capa de atenuación, porque flota sobre contenido arbitrario.

*Pendiente:* el estado al pasar el cursor.

### 9.6 Ajustes

Ventana con **losa flotante** de secciones (mismo lenguaje que la Consola):
General · Voz · IA · Claves y conexiones · Permisos · Avanzado.

**El tamaño de la ventana cambia con el panel.** Claves mide 820 × 560; los paneles v1 miden
720 × 520. Es correcto: la ventana de ajustes acomoda el tamaño del panel actual.

**Claves y conexiones** es el panel de referencia de la filosofía:
- Lista de servicios de **una línea** — nombre a la izquierda, estado a la derecha
- El registro seleccionado **se despliega en línea**: valor sellado + una sola línea mono de
  ficha (huella · añadida · llamadas) + dos acciones
- Los servicios sin clave son **filas de la misma lista**, no una sección aparte
- Al pie, una línea: «Todo se guarda en el Llavero de macOS.»

**El valor nunca se muestra como campo de texto.** Se enseña `sk-ant-` + **bloques de
redacción** + los cuatro últimos caracteres, con botón **Revelar** que pide **Touch ID**.
Es el cruce entre el moodboard (las barras censuradas del collage) y tres frases de la guía de
privacidad: guarda lo sensible en un llavero, nunca en texto plano, usa Touch ID.

### 9.7 Barra de menú — la marca, y nada más

El ítem de la barra es **sólo la marca de Miku**, a 16 pt. El estado no viaja en un
segundo glifo al lado: viaja **dentro de la marca**.

| Estado | Tratamiento | Se lee como |
|---|---|---|
| Sin conexión | marca al **35 %** de tinta | está instalada, no está viva |
| Reposo | la marca | esperando la palabra «Miku» |
| Escuchando · Pensando · Hablando · Anotando | marca + **núcleo** en la mitad baja de la cara | está en marcha |
| Silenciada | marca + **tache** en diagonal | la palabra de activación está apagada |

**Un solo tratamiento para los cuatro estados activos.** Escuchar, pensar y hablar se
turnan en segundos: un icono que cambia de forma tres veces por intercambio es ruido, no
información. El estado exacto vive en el panel, que es donde se mira cuando importa.

**El núcleo va donde va por geometría.** El círculo vacío más grande que cabe dentro de la
silueta está centrado en (0.50, 0.71) con radio 0.26 —la mitad baja de la cara—, así que un
punto de 0.115 ahí no toca ni el pelo ni los ojos a ninguna escala.

**El tache va de abajo-izquierda a arriba-derecha**, de esquina a esquina: es la dirección
de las variantes `.slash` de SF Symbols, y así el ítem habla el idioma de la barra. Se
dibuja dos veces —primero un corte ancho en el alfa, 0.05 a cada lado, y encima la línea de
0.075— para que se lea también donde cruza el pelo. El grosor se bajó desde 0.09 tras verlo
a tamaño real: a 0.09 el tache se comía la marca.

**Rechazado — marca + glifo de estado al lado.** Primer intento: marca a 18 pt y el SF
Symbol del estado a 11 pt pegado a su derecha. Conservaba las siete siluetas de §10, pero en
la barra real se leía como **dos apps distintas**, y sobresatura justo donde macOS pide una
idea por icono («*Create a recognizable, highly simplified design. Too many details can make
an interface icon confusing or unreadable*», HIG · Icons). La regla de §10 —cada estado, su
silueta— sigue valiendo **dentro de la app**; en la barra manda la marca.

**Lo que esto cuesta.** `Escuchando` y `Anotando` ya no se distinguen en la barra: las dos
son «en marcha». Se acepta porque macOS ya pone su propio indicador naranja de micrófono
cuando hay captura, y porque el panel lo dice con todas las letras. Si algún día `Anotando`
necesita su propia lectura, el sitio para meterla es la silueta —la cara llena, no un
segundo glifo.

La marca sale de `Logos/SVGS/MikuBLogo-1.svg`. `MikuApp/Scripts/make-icons.py` la convierte
en plantilla —la tinta del SVG pasa a ser alfa y el color se tira, que es lo único que la
barra respeta—, saca las tres variantes en 1x/2x/3x y de paso arma el `.icns`: marca blanca
sobre `fondo/lienzo`, que sólo se ve en el Finder porque Miku es `LSUIElement`.

---

## 10. Componentes

**`Indicador de estado`** — set de variantes con los estados, para **dentro de la app**
(cápsula de portada, cabecera del panel, filas de Actividad). Cada uno tiene **silueta
propia** porque en monocromo dos estados que sólo se distingan por color son el mismo
icono. La barra de menú no usa este set: allí manda la marca (§9.7).

| Estado | Forma | Significa |
|---|---|---|
| Reposo | Anillo vacío | Esperando la palabra «Miku» |
| Escuchando | Anillo con núcleo | Sesión abierta, te está oyendo |
| Pensando | Arco que gira | Procesando lo que le dijiste |
| Hablando | Onda | Reproduciendo la respuesta |
| Anotando | Texto con «+» | Transcribiendo la sala, sin responder |
| Silenciada | Anillo tachado | Palabra de activación desactivada |
| Sin conexión | Triángulo de aviso | No encuentra el motor |

**Marcas de estado en listas** (mismo idioma en toda la app):

| Marca | Significa |
|---|---|
| Círculo relleno | Hecho / válido |
| Triángulo | Requiere atención / caduca |
| Cuadrado | Error / fallido |
| Anillo hueco | Sin configurar / en curso |

*Pendiente de componentizar:* botones, chips, filas de lista, cápsula. Están construidos pero
no son componentes reales.

---

## 11. Reglas duras

1. **El acento son dos tokens.** `acento/relleno` para superficies, `acento/tinta` para texto.
2. **El estado se reconoce por forma**, el color sólo refuerza.
3. **El rojo es sólo error y destructivo.** Nada de rojo «de grabación».
4. **Vidrio sobre contenido lleva capa de atenuación.**
5. **El vidrio es para la capa funcional.** Contenido nunca.
6. **Ni epígrafes en mayúsculas sobre cada bloque, ni descripciones bajo cada ítem.**
   Si un panel se siente pobre, añade jerarquía, no etiquetas.
7. **Una sola insignia por región.**
8. **No hay selector de tema propio.** Se respeta el del sistema.
9. **No hay «cerrar sesión».** Miku es local.
10. **Los secretos no se muestran nunca como texto editable.**
11. **Sin pesos Light.** Regular es el más ligero.
12. **Todo el copy en español**, en frase (no Título Ni MAYÚSCULAS), salvo las etiquetas HUD
    que van en mayúsculas por regla tipográfica.

---

## 12. Contenido y voz

- **Frases cortas y activas.** «Convertir en nota», no «Conversión de la nota».
- **El botón dice lo que pasa.** Y el mismo verbo se mantiene por todo el flujo.
- **Nada de «lo que tú dices»** al hablar de la escucha: Miku captura la sala, no sólo al
  usuario. Lenguaje neutro sobre quién habla.
- **Los errores no piden perdón** y nunca son vagos: dicen qué pasó y cómo arreglarlo.
  «No empieza por sk-ant-», no «Clave inválida».
- **Transparencia sobre la IA** donde toque: «Miku es una IA y puede equivocarse. Revisa lo
  importante antes de darlo por hecho.»
- **`Denegar` es el botón por defecto** en la confirmación de acciones, a propósito: un Enter
  accidental no debe ejecutar nada.

---

## 13. Accesibilidad

Comprobado y a mantener:

- **Contraste mínimo 4,5:1** para texto hasta 17 pt. Todos los tokens de texto lo cumplen
  contra su fondo previsto. `texto/terciario` está en ~4,7:1 en ambos modos — es el más
  ajustado, no lo bajes.
- **Nunca sólo color.** Cada estado lleva forma; cada insignia lleva número o símbolo.
- **Tamaño de control en escritorio:** 28×28 pt por defecto, 20×20 mínimo. Las filas de
  navegación miden 38 pt de alto.
- **Suelo tipográfico:** 10 pt en escritorio. Nada baja de 11.
- **Alternativa a la voz siempre presente:** la entrada de texto en Conversación no es un
  extra, es el camino accesible para quien no puede o no quiere hablar.
- **Al usar fuentes que no son del sistema**, hay que replicar a mano el comportamiento de
  escalado de texto accesible, que con SF Pro venía gratis (§17).

---

## 14. Guías que sostienen decisiones

Citadas en su momento, resumidas aquí:

| Decisión | Principio |
|---|---|
| Portada vacía, resto en vistas | *No obscurezcas la información esencial amontonando detalles no esenciales; hazla disponible en otras partes de la ventana o en una vista adicional* |
| Contenido a sangre bajo el sidebar | *Los controles y la navegación aparecen sobre el contenido, no en el mismo plano* |
| Dos tokens de acento | *Texto hasta 17 pt necesita contraste 4,5:1* |
| Forma antes que color | *Ofrece indicadores visuales, como formas o iconos distintos, además del color* |
| Rojo reservado | *Evita usar el mismo color para significar cosas distintas* |
| Capa de atenuación | Vidrio *clear* sobre contenido claro necesita capa de atenuación |
| Personalización en popover, no en Ajustes | *Lo que muestra u oculta partes de la vista actual debe estar en esa pantalla* |
| Sin botón Ajustes en la toolbar | *Evita añadir botones de ajustes a la barra de herramientas* |
| Sin selector de tema | *Evita ofrecer un ajuste de apariencia propio de la app* |
| Ventana de ajustes de tamaño variable | *La ventana de ajustes acomoda el tamaño del panel actual* |
| Sin cuenta ni cerrar sesión | *Pide crear una cuenta sólo si tu funcionalidad principal la necesita* |
| Clave en Llavero + Touch ID | *Guarda lo sensible en un llavero seguro* · *nunca en texto plano* · *usa Touch ID* |
| Sin pesos Light | *Evita Ultralight, Thin y Light, especialmente en texto pequeño* |
| Etiquetar turnos y mostrar herramientas | *Comunica dónde tu app usa IA* · *nunca engañes a alguien haciéndole creer que interactúa con un humano* |

---

## 15. Estructura del archivo Figma

**`Page 1`** — exploración original del usuario. **No tocar.**

**`01 · Fundamentos`** — tablero de dirección, paleta completa con los dos valores por token,
espécimen tipográfico, métrica y el aviso de contraste del acento. Duplicado en Oscuro y Claro.

**`02 · Componentes`** — set de variantes `Indicador de estado` + tablero que explica los seis
estados.

**`03 · Pantallas`** — organizado por filas:

| y | Contenido |
|---|---|
| 0 | Consolas **oscuras**: Inicio enfoque · Inicio · Conversación · Actividad |
| 900 | Notas oscura · popover de opciones · menú del perfil · Ajustes Claves oscuro |
| ~860 | Sección `Cómo reacciona la portada` (cuatro estados) |
| 1800 | Consolas **claras** (las cinco) |
| 2600 | Sección `v1 · Consola densa — sólo referencia, no usar` |
| 2700 | Ajustes Claves claro |
| 3500 | Ciclo de vida de una credencial (oscuro y claro) |
| 4400 | Sección `Superficies secundarias · vigentes` (avatar flotante, Ajustes IA) |
| 5300 | Sección `Consola en contexto · MacBook` |

> La sección del MacBook tiene copias duplicadas y anidadas de los marcos de enfoque
> (`MacBook Air - 1` a `- 4`, más dos `Menu Bar` sueltas). Conviene limpiarla a mano:
> quedarse con una oscura y una clara.

---

## 16. Trampas de la API de Figma

Cada una costó al menos un intento fallido.

1. **`vectorPaths` normaliza la caja al trazado real.** Si el trazado no cubre toda la caja
   que esperas (por ejemplo un arco parcial), el nodo se desplaza. Solución: calcular el
   mínimo de las coordenadas del trazado y fijar `x`/`y` a ese mínimo.

2. **No se pueden colgar propiedades propias de un nodo.** `node.__loQueSea = x` lanza
   *no such property*. Pasa los valores como argumentos.

3. **`t.textStyleId` no casa con `style.id`** — el id del estilo lleva una coma final. Un
   barrido que busque el estilo en un mapa por ese id **falla en silencio** y trata todos los
   nodos como huérfanos. Para saber qué fila está seleccionada, usa la **píldora de acento**
   (`row.fills.length > 0`) como fuente de verdad, no la fuente del texto.

4. **`openTypeFeatures` no se puede escribir**, ni siquiera fusionando el mapa
   (`object is not extensible`). Las cifras tabulares van a mano.

5. **Filtrar textos por `characters` falla con `textCase: UPPER`.** El nodo guarda
   «Escucha 12:04» y se ve «ESCUCHA 12:04». Compara en mayúsculas o por nombre de nodo.

6. **Un error revierte todo el script.** Las llamadas son transaccionales: si el paso 9 falla,
   los 8 anteriores no se guardaron. Trabaja en pasos pequeños.

7. **`layoutSizing*` y `*AxisSizingMode` son enums distintos.** El hijo usa
   `FIXED|HUG|FILL`; el marco usa `FIXED|AUTO`.

8. **Para diagnosticar diferencias entre temas, mide antes de tocar.** Lee
   `resolvedVariableModes`, los `valuesByMode` de la variable ligada, y los límites de cada
   hijo frente a su marco. Dos veces pareció un fallo de color y era geometría (un hijo
   desbordando) o atenuación óptica.

---

## 17. Notas de implementación (SwiftUI)

- **Hay que empaquetar Geist e IBM Plex Mono** en el `.app`. Ambas son open source. Al dejar
  SF Pro se pierde el escalado de texto accesible automático: **hay que replicarlo a mano**.
- **Los tokens de color van a un `Color` semántico** con variantes claro/oscuro, no a valores
  fijos. Los nombres del sistema (`fondo/vidrio`, `acento/tinta`…) deberían sobrevivir al
  código para que diseño e implementación hablen igual.
- **El vidrio** es `.ultraThinMaterial` / `.regularMaterial` más la capa de atenuación encima
  del fondo y debajo del contenido.
- **Los iconos del diseño están nombrados con su SF Symbol** —
  `icono (SF Symbol: house)`, `waveform`, `note.text`, `clock.arrow.circlepath`, `key`,
  `lock.shield`, `gearshape`, `slider.horizontal.3`, `touchid`, `magnifyingglass`,
  `sidebar.left`, `person.crop.circle`, `bell`, `arrow.down.circle`, `power`, `cpu`,
  `chevron.up.chevron.down`, `bubble.left.and.bubble.right`. Usa el símbolo real, no el dibujo.
- **El anillo graduado es un medidor real**: debe reflejar el nivel de entrada del micrófono.
  Si se implementa como decoración estática, pierde su justificación.
- **Reduce Motion:** el aura que respira, el arco que gira y la onda deben pararse cuando el
  sistema lo pide.
- **La ventana de ajustes se abre desde el menú de la app y `⌘,`**, y su tamaño cambia por panel.

---

## 18. Qué falta

**Diseño:**
- Vista **Transcripciones** (la única de las cinco sin diseñar)
- **Primer arranque** — cinco pasos: bienvenida, permisos, cerebro, voz, «di Miku»
- **Ventana de confirmación** de acciones como pieza propia (existe el contenido, no la pantalla)
- Estado **al pasar el cursor** del avatar flotante
- Secciones **General / Voz / Permisos / Avanzado** de Ajustes con el lenguaje nuevo
  (sólo IA y Claves están hechas; IA está en la sección de superficies vigentes con el
  diseño v1 y habría que reescribirla)
- **Componentizar** botones, chips, filas y cápsula

**Bloqueado:**
- **Miku con los ojos cerrados.** El render actual los tiene abiertos y es una imagen plana;
  Figma no puede cerrarlos. Hay que **reexportar el modelo 3D** en esa pose. La composición
  ya está pensada para ello: con los ojos cerrados y el aura, «en reposo» se leerá mucho mejor.

**Higiene del archivo:**
- Limpiar los duplicados de la sección `Consola en contexto · MacBook`
- Decidir si se borra la sección `v1` una vez el diseño esté implementado
