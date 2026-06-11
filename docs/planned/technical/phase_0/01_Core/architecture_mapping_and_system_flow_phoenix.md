# Architecture Mapping & System Flow

lib/
├── music_learning/                         # CONTEXT CORE (Phoenix Context Layer)
│
│   ├── application.ex                      # App entry
│
│   ├── state/                              # STATE MODEL (CONTROL GLOBAL)
│   │   ├── state_model.ex                  # estado global (song, level, playback)
│   │   ├── playback_state.ex              # play/pause/stop/tempo
│   │   └── session_state.ex               # estado por usuario/session
│
│   ├── sync/                               # SYNC ENGINE (CORE MUSICAL)
│   │   ├── sync_engine.ex                 # orquestador principal
│   │   ├── time_coordinator.ex           # sincronización tiempo real
│   │   └── note_tracker.ex               # tracking de nota actual
│
│   ├── timeline/                           # EVENT TIMELINE (VERDAD MUSICAL)
│   │   ├── event_timeline.ex             # builder principal
│   │   ├── musicxml_parser.ex           # MusicXML → events
│   │   ├── timeline_builder.ex          # construcción de secuencia
│   │   └── timeline_event.ex            # estructura de evento musical
│
│   ├── songs/                              # DATA LAYER (DOMINIO MUSICAL)
│   │   ├── song.ex                       # entidad canción
│   │   ├── level.ex                      # niveles de dificultad
│   │   ├── song_library.ex              # selector de canciones
│   │   └── song_loader.ex              # carga desde archivos
│
│   ├── workers/                            # BACKGROUND JOBS
│   │   ├── musicxml_worker.ex          # procesamiento MusicXML
│   │   ├── level_generator_worker.ex   # generación niveles
│   │   └── preprocessing_worker.ex     # normalización y cache
│
│   ├── playback/                           # AUDIO CONTROL (BRIDGE TO JS)
│   │   ├── playback_controller.ex       # comandos play/pause/stop
│   │   ├── tempo_controller.ex          # velocidad
│   │   └── audio_sync.ex                # coordinación con JS
│
│   ├── visual/                             # VISUAL LAYER LOGIC
│   │   ├── color_mapper.ex              # notas → colores
│   │   ├── notation_config.ex           # config visual (show/hide)
│   │   └── highlight_engine.ex          # notas activas UI
│
│   └── music_learning.ex                 # CONTEXT MAIN ENTRY
│
├── music_learning_web/                    # WEB LAYER (LIVEVIEW + JS BRIDGE)
│
│   ├── live/
│   │   ├── song_live/
│   │   │   ├── show.ex                  # pantalla principal
│   │   │   ├── controls_component.ex     # play/pause/speed
│   │   │   ├── score_component.ex        # partitura OSMD
│   │   │   └── settings_component.ex     # config visual
│
│   ├── hooks/                            # JS BRIDGE LAYER
│   │   ├── osmd_hook.js                 # render partituras
│   │   ├── tone_player_hook.js          # audio engine
│   │   └── sync_hook.js                 # sync frontend-backend
│
│   ├── components/
│   └── router.ex
│
└── music_learning_web.js                 # entry JS (hooks bootstrap)


Mapeo arquitectura → código

State Model
lib/music_learning/state/

Event Timeline
lib/music_learning/timeline/

Sync Engine
lib/music_learning/sync/

Playback (bridge JS)
lib/music_learning/playback/

Visual system
lib/music_learning/visual/

Workers
lib/music_learning/workers/

UI (LiveView)
lib/music_learning_web/live/

JS Bridge
lib/music_learning_web/hooks/

Flujo del sistema

MusicXML
   ↓
Workers (preprocess)
   ↓
Event Timeline
   ↓
Sync Engine
   ↓
State Model
   ↓
LiveView
   ↓
JS Bridge
   ↓
OSMD + Tone.js
