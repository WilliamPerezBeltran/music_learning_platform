# Arquitectura Core — Capas del Sistema

## ¿Qué hace el sistema?

Define la estructura completa de capas del backend: dominio, aplicación, infraestructura y estado.
Implementa todos los schemas de base de datos, las migraciones, y la fachada pública que los LiveViews usan para comunicarse con el sistema.

---

## ¿Cómo está construido?

### Estructura de archivos

```
lib/music_learning_platform/
├── music_learning.ex                              ← fachada pública (único punto de entrada para LiveViews)
│
├── domain/                                        ← entidades y reglas del negocio musical
│   ├── songs/
│   │   ├── song.ex                                ← entidad base: título, categoría, metadatos
│   │   ├── song_version.ex                        ← nivel pedagógico (melody | simplified | chords | full)
│   │   └── content_asset.ex                       ← archivos asociados (musicxml | audio | image | midi)
│   ├── timeline/
│   │   ├── music_timeline.ex                      ← estructura temporal procesada (bpm, duración, resolución)
│   │   └── musical_event.ex                       ← unidad mínima de sincronización (nota con tiempo)
│   └── playback/
│       └── playback_session.ex                    ← estado runtime del usuario (play/pause/speed/position)
│
├── application/                                   ← casos de uso y orquestación
│   ├── songs/
│   │   ├── song_library.ex                        ← CRUD de canciones y versiones
│   │   └── song_loader_service.ex                 ← carga canción + timeline para reproducción
│   ├── playback/
│   │   ├── playback_controller.ex                 ← play / pause / stop / seek
│   │   └── tempo_controller.ex                    ← control de velocidad (0.5x – 2.0x)
│   ├── sync/
│   │   ├── sync_engine.ex                         ← coordinador audio + visual
│   │   ├── time_coordinator.ex                    ← cálculo de tiempo elapsed
│   │   └── note_tracker.ex                        ← eventos activos en un instante dado
│   └── visual/
│       ├── color_mapper.ex                        ← pitch → color (Do=rojo, Re=naranja, etc.)
│       ├── notation_config.ex                     ← toggles de configuración visual del usuario
│       └── highlight_engine.ex                    ← payload de highlight para el JS hook
│
├── infrastructure/                                ← implementación técnica (DB, archivos, workers)
│   ├── musicxml/
│   │   ├── musicxml_parser.ex                     ← parsea XML → notas con tiempo
│   │   └── timeline_builder.ex                    ← persiste MusicTimeline + MusicalEvents en DB
│   ├── workers/
│   │   ├── musicxml_worker.ex                     ← orquesta el pipeline completo de procesamiento
│   │   ├── preprocessing_worker.ex                ← preprocesa todas las versiones de una canción
│   │   └── level_generator_worker.ex              ← genera los niveles estándar de una canción
│   └── storage/
│       └── file_storage.ex                        ← lectura/escritura de archivos en priv/static/songs/
│
└── state/                                         ← estado runtime (ETS, no persistente)
    ├── state_model.ex                             ← operaciones sobre el estado de sesión en ETS
    ├── playback_state.ex                          ← ciclo de vida de sesiones (crear/destruir/consultar)
    └── session_state.ex                           ← configuración visual por sesión
```

### Tablas de base de datos

| Tabla | Propósito |
|---|---|
| `songs` | Canciones base del sistema |
| `song_versions` | Niveles pedagógicos por canción |
| `music_timelines` | Estructura temporal procesada por versión |
| `musical_events` | Notas individuales con tiempos exactos |
| `playback_sessions` | Estado de reproducción persistible |
| `content_assets` | Archivos asociados a canciones |

---

## ¿Cómo funciona internamente?

### Regla principal

Los LiveViews **nunca** llaman a `Repo`, `Workers`, ni al parser directamente.
Solo hablan con `MusicLearningPlatform.MusicLearning`:

```elixir
# En un LiveView
MusicLearningPlatform.MusicLearning.play(session_id)
MusicLearningPlatform.MusicLearning.list_songs()
MusicLearningPlatform.MusicLearning.toggle_notation(session_id, :colors)
```

### Flujo de capas

```
LiveView
    ↓
MusicLearning (fachada)
    ↓
Application Services (PlaybackController, SyncEngine, SongLibrary...)
    ↓
Domain (Song, SongVersion, MusicTimeline, MusicalEvent...)
    ↓
Infrastructure (Repo, MusicXMLParser, FileStorage...)
```

### Estado runtime (ETS)

El estado de reproducción vive en una tabla ETS `:playback_states` inicializada al arrancar la app:

```
application.ex → PlaybackState.init_table() → :ets.new(:playback_states, [:named_table, :public])
```

Cada sesión LiveView tiene una entrada `{session_id, %StateModel{}}` en ETS.
No es persistente — se pierde al reiniciar la app (comportamiento esperado en Fase 0).

### Sistema de colores

`ColorMapper` mapea la nota musical a un color fijo:

| Nota | Color |
|---|---|
| C (Do) | `#FF4444` rojo |
| D (Re) | `#FF8C00` naranja |
| E (Mi) | `#FFD700` amarillo |
| F (Fa) | `#32CD32` verde |
| G (Sol) | `#1E90FF` azul |
| A (La) | `#8A2BE2` violeta |
| B (Si) | `#FF69B4` rosa |

### Arranque del sistema (actualizado)

```
mix phx.server
    ↓
MusicLearningPlatform.Application.start/2
    ↓
PlaybackState.init_table()                         ← tabla ETS inicializada
    ↓
Supervisor inicia:
  ├── MusicLearningPlatform.Repo
  ├── MusicLearningPlatformWeb.Endpoint
  └── MusicLearningPlatform.PubSub
```

---

## ¿Cómo se modifica sin romperlo?

### Agregar una nueva entidad

1. Crear schema en `domain/`
2. Generar migración: `mix ecto.gen.migration create_{tabla}`
3. Agregar operaciones en `application/`
4. Exponer en `music_learning.ex` si los LiveViews lo necesitan

### Agregar una operación de reproducción

1. Implementar en `application/playback/playback_controller.ex`
2. Si modifica estado, agregar operación en `state/state_model.ex`
3. Exponer en `music_learning.ex`

### Agregar un toggle de configuración visual

1. Agregar campo en `%NotationConfig{}` en `application/visual/notation_config.ex`
2. Agregar cláusula `toggle/2`
3. El LiveView llama `MusicLearning.toggle_notation(session_id, :nuevo_campo)`

### Verificar que nada se rompió

```bash
mix precommit
```
