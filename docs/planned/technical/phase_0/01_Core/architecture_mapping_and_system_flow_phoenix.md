# Architecture Mapping — Strict Phoenix Context Architecture

## Objetivo

Separar claramente:

* Presentation Layer
* Application Layer
* Domain Layer
* Infrastructure Layer

Manteniendo la filosofía de Phoenix Contexts.

---

# Estructura General

```text
lib/
├── music_learning/
│
│   ├── music_learning.ex
│
│   ├── domain/
│   │
│   │   ├── songs/
│   │   │   ├── song.ex
│   │   │   ├── song_version.ex
│   │   │   └── content_asset.ex
│   │   │
│   │   ├── timeline/
│   │   │   ├── music_timeline.ex
│   │   │   └── musical_event.ex
│   │   │
│   │   └── playback/
│   │       └── playback_session.ex
│
│   ├── application/
│   │
│   │   ├── songs/
│   │   │   ├── song_library.ex
│   │   │   └── song_loader_service.ex
│   │   │
│   │   ├── playback/
│   │   │   ├── playback_controller.ex
│   │   │   └── tempo_controller.ex
│   │   │
│   │   ├── sync/
│   │   │   ├── sync_engine.ex
│   │   │   ├── time_coordinator.ex
│   │   │   └── note_tracker.ex
│   │   │
│   │   └── visual/
│   │       ├── color_mapper.ex
│   │       ├── notation_config.ex
│   │       └── highlight_engine.ex
│
│   ├── infrastructure/
│   │
│   │   ├── persistence/
│   │   │   ├── repo.ex
│   │   │   └── schemas/
│   │   │
│   │   ├── musicxml/
│   │   │   ├── musicxml_parser.ex
│   │   │   └── timeline_builder.ex
│   │   │
│   │   ├── workers/
│   │   │   ├── musicxml_worker.ex
│   │   │   ├── preprocessing_worker.ex
│   │   │   └── level_generator_worker.ex
│   │   │
│   │   └── storage/
│   │       └── file_storage.ex
│
│   └── state/
│       ├── playback_state.ex
│       ├── session_state.ex
│       └── state_model.ex
│
├── music_learning_web/
│
│   ├── live/
│   │   ├── song_live/
│   │   └── components/
│   │
│   ├── hooks/
│   │   ├── osmd_hook.js
│   │   ├── tone_player_hook.js
│   │   └── sync_hook.js
│   │
│   ├── components/
│   └── router.ex
│
└── music_learning_web.ex
```

---

# Responsabilidades

## Presentation Layer

Ubicación:

```text
music_learning_web/
```

Responsable de:

* LiveViews
* Components
* Router
* Hooks JS
* Eventos UI

Nunca:

* Reglas de negocio
* Repo
* Parsing MusicXML

---

## Application Layer

Ubicación:

```text
music_learning/application/
```

Responsable de:

* Casos de uso
* Orquestación
* Coordinación de procesos

Ejemplos:

```text
SyncEngine
PlaybackController
SongLibrary
```

Pregunta que responde:

> ¿Qué debe hacer el sistema?

---

## Domain Layer

Ubicación:

```text
music_learning/domain/
```

Responsable de:

* Entidades
* Value Objects
* Reglas del negocio musical

Ejemplos:

```text
Song
SongVersion
MusicTimeline
MusicalEvent
PlaybackSession
```

Pregunta que responde:

> ¿Qué es el negocio?

---

## Infrastructure Layer

Ubicación:

```text
music_learning/infrastructure/
```

Responsable de:

* Base de datos
* MusicXML
* Archivos
* Workers
* APIs externas

Pregunta que responde:

> ¿Cómo se implementa técnicamente?

---

## Runtime State Layer

Ubicación:

```text
music_learning/state/
```

Responsable de:

* Estado temporal
* Reproducción activa
* Sesiones LiveView
* Sincronización runtime

No pertenece al dominio.

No representa información persistente.

---

# Flujo Final

```text
LiveView
    ↓
Context API
    ↓
Application Services
    ↓
Domain
    ↓
Infrastructure
```

Ejemplo:

```text
SongLive.Show
    ↓
MusicLearning.play_song()
    ↓
PlaybackController
    ↓
SyncEngine
    ↓
MusicTimeline
    ↓
MusicalEvent
    ↓
StateModel
    ↓
JS Hooks
```

---

# Regla Principal

Los LiveViews nunca conocen:

* Repo
* MusicXML
* Workers
* Parsing
* SQL

Los LiveViews solamente hablan con:

```elixir
MusicLearning
```

que actúa como fachada pública del Context.
