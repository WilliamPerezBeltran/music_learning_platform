# Sistema de Mapeo de Colores

## Archivos modificados

- `lib/music_learning_platform/application/visual/color_mapper.ex`
- `lib/music_learning_platform/application/visual/notation_config.ex`
- `assets/js/osmd_hook.js`
- `assets/css/app.css`
- `lib/music_learning_platform_web/live/song_live/show.ex`
- `test/music_learning_platform/application/visual/color_mapper_test.exs`
- `test/music_learning_platform/infrastructure/musicxml/timeline_builder_test.exs`
- `test/music_learning_platform_web/live/song_live_test.exs`

---

## Descripción

Cada nota musical tiene un color fijo según su nombre, sin importar la octava. Do3 y Do4 tienen el mismo color. Los colores se aplican automáticamente al cargar la partitura y el usuario puede activarlos o desactivarlos desde la barra de controles.

---

## Tabla de colores

| Nota | color_key | Hex       |
|------|-----------|-----------|
| Do (C) | `do`  | `#E53935` |
| Re (D) | `re`  | `#FB8C00` |
| Mi (E) | `mi`  | `#FDD835` |
| Fa (F) | `fa`  | `#43A047` |
| Sol (G)| `sol` | `#1E88E5` |
| La (A) | `la`  | `#8E24AA` |
| Si (B) | `si`  | `#E91E63` |

---

## Backend — `color_mapper.ex`

### `get_color_key/1`
Recibe el pitch de una nota (`"C4"`, `"F#3"`) y retorna la clave semántica (`"do"`, `"fa"`). Ignora la octava y los accidentales — solo usa la letra base.

### `color_for_pitch/1`
Alias de `get_color_key/1`. Mantiene compatibilidad con `timeline_builder.ex`.

### `get_hex/1`
Convierte una clave semántica a su valor hexadecimal. Retorna `"#000000"` si la clave no existe.

El `color_key` se almacena en cada `MusicalEvent` al construir el timeline desde MusicXML.

---

## Frontend — `osmd_hook.js`

OSMD colorea las notas automáticamente usando `coloringMode: 2` (CustomColorSet) con el array `NOTE_COLOR_SET` (C→B + silencio) en las opciones del constructor. No requiere iteración manual de notas.

El mapa `COLOR_KEY_HEX` permite resolver `"do"` → `"#E53935"` en el lado JS para operaciones de highlight.

### Toggle de colores

El botón de paleta en la barra de controles envía el evento `toggle_colors` al servidor. El servidor alterna el booleano `colors_enabled` y hace `push_event` al hook. El hook agrega o quita la clase CSS `colors-disabled` en el contenedor de la partitura — sin re-renderizar OSMD.

```css
.colors-disabled path,
.colors-disabled ellipse {
  fill: black !important;
  stroke: black !important;
}
```

Este enfoque CSS es más confiable que `osmd.setOptions()` + `osmd.render()`, que en OSMD 1.9.9 no reactiva el coloreado correctamente.

---

## LiveView — `show.ex`

- Assign `colors_enabled: true` inicializado en `mount/3`
- Handler `toggle_colors` alterna el booleano y hace `push_event("toggle_colors", %{enabled: bool})`
- Botón con ícono swatch en la barra de controles, resaltado en `btn-primary` cuando los colores están activos
