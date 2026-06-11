# Integración OSMD — Renderizado de Partituras

## ¿Qué hace el sistema?

Renderiza archivos MusicXML como partituras SVG interactivas en el navegador usando OpenSheetMusicDisplay (OSMD).
Permite cambiar entre canciones y niveles sin recargar la página.
El sistema es responsive: funciona en mobile, tablet, desktop y TV.

---

## ¿Cómo está construido?

### Archivos

```
assets/js/
└── osmd_hook.js                               ← JS Bridge entre LiveView y OSMD

lib/music_learning_platform_web/
├── components/
│   └── layouts.ex                             ← Layouts.player añadido (sin max-width)
├── live/song_live/
│   └── show.ex                                ← LiveView principal del player
└── router.ex                                  ← rutas /songs y /songs/:id

lib/music_learning_platform/
└── music_learning.ex                          ← get_musicxml_content/1 añadido
```

### Rutas

| Ruta | LiveView | Acción |
|---|---|---|
| `/songs` | `SongLive.Show` | lista de canciones, sin selección |
| `/songs/:id` | `SongLive.Show` | carga y renderiza la canción seleccionada |

---

## ¿Cómo funciona internamente?

### Flujo completo

```
Usuario visita /songs/:id
        ↓
LiveView.handle_params/3
        ↓
MusicLearning.get_song/1          ← obtiene Song + SongVersions de DB
MusicLearning.list_song_versions/1
        ↓
MusicLearning.get_musicxml_content/1
        ↓
FileStorage.read(musicxml_path)   ← lee el XML de priv/static/songs/
        ↓
push_event("load_score", %{musicxml: content})
        ↓
OsmdHook.loadScore(musicxml)      ← JS: inicializa OSMD, render SVG
        ↓
osmd.load(xml) → osmd.render()
        ↓
applyNoteColors()                 ← colorea cada nota según pitch
        ↓
pushEvent("score_loaded", {total_notes})
        ↓
LiveView.handle_event("score_loaded")  ← actualiza contador de notas
```

### Eventos LiveView ↔ Hook

| Dirección | Evento | Payload | Acción |
|---|---|---|---|
| LiveView → Hook | `load_score` | `{ musicxml: "..." }` | Inicializa OSMD y renderiza |
| LiveView → Hook | `highlight_note` | `{ index: N, color_key: "#..." }` | Resalta nota activa |
| LiveView → Hook | `clear_highlight` | `{}` | Limpia resaltado |
| Hook → LiveView | `score_loaded` | `{ total_notes: N }` | Confirma render completo |

### Colores de notas

Los colores se aplican en `applyNoteColors()` al finalizar el render, iterando sobre `GraphicSheet.MeasureList`:

| Nota | Color |
|---|---|
| C (Do) | `#FF4444` |
| D (Re) | `#FF8C00` |
| E (Mi) | `#FFD700` |
| F (Fa) | `#32CD32` |
| G (Sol) | `#1E90FF` |
| A (La) | `#8A2BE2` |
| B (Si) | `#FF69B4` |

### Responsive

| Breakpoint | Sidebar | Layout |
|---|---|---|
| Mobile (`< md`) | Oculto, slide-in con hamburguesa + overlay | Vertical |
| Tablet (`md+`) | Siempre visible, `w-56` | Horizontal |
| Desktop (`lg+`) | `w-64` | Horizontal |
| TV (`xl+`) | `w-72` | Horizontal |

`min-h-dvh` reemplaza `h-screen` para evitar recorte en browsers mobile con barra de navegación.

### Layout del player — por qué no usa `Layouts.app`

El layout por defecto de Phoenix (`Layouts.app`) envuelve todo el contenido en:

```html
<main class="px-4 py-20 sm:px-6 lg:px-8">
  <div class="mx-auto max-w-2xl space-y-4">
    ...
  </div>
</main>
```

Esto limita el ancho máximo a `max-w-2xl` (672 px). OSMD calcula el número de compases por sistema en función del ancho disponible del contenedor — con 672 px genera muchos sistemas apilados verticalmente y la partitura se corta.

**Solución:** se añadió `Layouts.player` en `layouts.ex`, un layout sin restricciones de ancho:

```elixir
def player(assigns) do
  ~H"""
  <.flash_group flash={@flash} />
  {render_slot(@inner_block)}
  """
end
```

`show.ex` usa `<Layouts.player flash={@flash}>` en lugar de `<Layouts.app>`. El contenido ocupa el 100 % del viewport y OSMD puede distribuir los compases correctamente en todos los tamaños de pantalla.

---

## ¿Cómo se modifica sin romperlo?

### Agregar un nuevo evento LiveView → Hook

1. En el LiveView: `push_event(socket, "mi_evento", %{dato: valor})`
2. En `osmd_hook.js`: `this.handleEvent("mi_evento", ({ dato }) => { ... })`

### Agregar un evento Hook → LiveView

1. En `osmd_hook.js`: `this.pushEvent("mi_evento", { dato: valor })`
2. En el LiveView: `def handle_event("mi_evento", %{"dato" => valor}, socket)`

### Cambiar los colores de notas

Editar el mapa `noteColorMap` en `applyNoteColors()` dentro de `osmd_hook.js`.
Los colores CSS en `app.css` (`.note-do`, `.note-re`, etc.) son para el resaltado activo — deben mantenerse consistentes.

### Agregar una canción nueva

Ver `docs/implemented/technical_documentation/musicxml_integration.md`.
