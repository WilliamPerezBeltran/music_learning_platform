# Music Learning Platform

Plataforma web para aprender piano usando un sistema de notación musical por colores. Cada nota tiene un color fijo según su nombre (Do = rojo, Re = naranja, Mi = amarillo, etc.), lo que permite a niños y principiantes leer partituras sin saber teoría musical.

Construida con **Elixir + Phoenix 1.8 + LiveView + Tone.js + OSMD + PostgreSQL 16**. Sin SPA, sin frontend separado.

---

## Tabla de contenidos

1. [Stack](#stack)
2. [Versiones del entorno](#versiones-del-entorno)
3. [Requisitos](#requisitos)
4. [Inicio rápido](#inicio-rápido)
5. [Comandos](#comandos)
6. [Arquitectura](#arquitectura)
7. [Base de datos](#base-de-datos)
8. [Entidades del dominio](#entidades-del-dominio)
9. [Módulos principales](#módulos-principales)
10. [Sistema de colores](#sistema-de-colores)
11. [Reproducción y sincronización](#reproducción-y-sincronización)
12. [Rutas](#rutas)
13. [Fase 0 — Validación técnica](#fase-0--validación-técnica)
14. [Tests](#tests)
15. [Variables de entorno](#variables-de-entorno)
16. [Docker](#docker)
17. [Documentación](#documentación)
18. [Ramas y commits](#ramas-y-commits)
19. [Decisiones de diseño](#decisiones-de-diseño)

---

## Stack

| Capa | Tecnología |
|---|---|
| Lenguaje | Elixir 1.19.5 |
| Framework web | Phoenix 1.8.5 |
| UI / Tiempo real | Phoenix LiveView 1.1 |
| Motor de audio | Tone.js 15.1.22 |
| Renderizado de partitura | OpenSheetMusicDisplay (OSMD) 1.9.9 |
| Formato musical | MusicXML |
| Base de datos | PostgreSQL 16.14 |
| CSS | Tailwind v4 + DaisyUI |
| Iconos | Heroicons v2.2 |
| Almacenamiento de archivos | Cloudflare R2 |
| Servidor HTTP | Bandit |

---

## Versiones del entorno

```bash
elixir --version
```

```text
Erlang/OTP 28 [erts-16.1]
Elixir 1.19.5 (compiled with Erlang/OTP 28)
```

```bash
mix phx.new --version
```

```text
Phoenix installer v1.8.5
```

---

## Requisitos

- Elixir 1.19+
- Erlang/OTP 27+
- PostgreSQL 16+
- Node.js 18+ (solo para gestión de assets fuera de Docker)

O simplemente **Docker + Docker Compose** (recomendado).

---

## Inicio rápido

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd music_learning_platform

# 2. Levantar app + base de datos
docker compose up --build

# 3. En otra terminal, correr migraciones y seeds
docker compose exec app mix ecto.migrate
docker compose exec app mix run priv/repo/seeds.exs
```

Abrir [http://localhost:4000](http://localhost:4000) en el navegador.

Navegar a `/songs` → seleccionar una canción → presionar play.

---

## Comandos

```bash
# Desarrollo
docker compose up                                         # Arrancar app + DB
docker compose up --build                                 # Reconstruir imagen
docker compose exec app iex -S mix                        # Consola interactiva

# Base de datos
docker compose exec app mix ecto.migrate                  # Aplicar migraciones
docker compose exec app mix ecto.reset                    # Drop + recrear + migrar
docker compose exec app mix run priv/repo/seeds.exs       # Cargar datos de prueba

# Assets
docker compose exec app mix assets.build                  # Compilar CSS y JS

# Testing
docker compose exec -e MIX_ENV=test app mix test                              # Suite completa
docker compose exec -e MIX_ENV=test app mix test test/path/to/file_test.exs   # Archivo específico
docker compose exec -e MIX_ENV=test app mix test --failed                     # Solo fallidos

# Logs
docker compose logs -f app                                # Logs en tiempo real
```

---

## Arquitectura

El backend **no reproduce audio ni renderiza música**. Solo coordina el estado y distribuye eventos al frontend vía LiveView.

```
MusicXML → Workers → Event Timeline → Sync Engine → State Model
                                                          ↓
                                                      LiveView
                                                          ↓
                                                      JS Bridge
                                                     ↙        ↘
                                                 OSMD       Tone.js
```

### Responsabilidades por capa

| Capa | Responsabilidad |
|---|---|
| **State Model** | Fuente de verdad en runtime: canción activa, nivel, play/pause, tempo |
| **Event Timeline** | MusicXML → eventos con tiempo exacto. Fuente de verdad musical |
| **Sync Engine** | Mantiene audio + visual sincronizados contra el timeline |
| **JS Bridge (hooks)** | Comunicación bidireccional LiveView ↔ OSMD / Tone.js |
| **Workers** | Procesamiento async de MusicXML, generación de niveles |
| **OSMD** | Renderizado SVG del pentagrama + resaltado de notas |
| **Tone.js** | Reproducción de audio, Transport scheduler, control de BPM |

### Estructura de código

```
lib/
├── music_learning_platform/
│   ├── state/           # state_model.ex, playback_state.ex, session_state.ex
│   ├── sync/            # sync_engine.ex, time_coordinator.ex, note_tracker.ex
│   ├── timeline/        # event_timeline.ex, musicxml_parser.ex, timeline_builder.ex
│   ├── songs/           # song.ex, level.ex, song_library.ex, song_loader.ex
│   ├── workers/         # musicxml_worker.ex, level_generator_worker.ex
│   ├── playback/        # playback_controller.ex, tempo_controller.ex, audio_sync.ex
│   └── visual/          # color_mapper.ex, notation_config.ex, highlight_engine.ex
└── music_learning_platform_web/
    ├── live/song_live/  # show.ex, controls_component.ex, score_component.ex
    ├── hooks/           # osmd_hook.js, tone_player_hook.js, sync_hook.js
    └── router.ex
```

---

## Base de datos

### Tablas

| Tabla | Descripción |
|---|---|
| `songs` | Canción base: título, categoría, duración, estado de publicación |
| `song_versions` | Versión pedagógica de una canción: melody, simplified, chords, full |
| `music_timelines` | Estructura temporal procesada: BPM, duración total |
| `musical_events` | Evento mínimo de sincronización: pitch, start_time, end_time, color_key |
| `playback_sessions` | Estado de reproducción en tiempo real por sesión |
| `content_assets` | Archivos asociados a una canción: MusicXML, audio, imagen, MIDI |

### Historial de migraciones

| Migración | Descripción |
|---|---|
| `20260611181440` | Tabla `songs` con índices por categoría y publicación |
| `20260611181445` | Tabla `song_versions` (niveles pedagógicos) |
| `20260611181446` | Tabla `music_timelines` |
| `20260611181447` | Tabla `playback_sessions` |
| `20260611181448` | Tabla `content_assets` |
| `20260611181449` | Tabla `musical_events` con índices por timeline y start_time |

---

## Entidades del dominio

### `Song`

Entidad base. Representa una canción disponible en la plataforma.

```elixir
%Song{
  title: "Bartolito",
  artist: "tradicional",
  category: "infantil",
  is_published: true
}
```

### `SongVersion`

Versión pedagógica de una canción. Una canción puede tener múltiples versiones ordenadas por dificultad.

```elixir
%SongVersion{
  song_id: 1,
  version_type: "melody",   # melody | simplified | chords | full
  level_index: 1,
  name: "Solo melodía",
  musicxml_path: "bartolito_level1.xml"
}
```

### `MusicTimeline`

Estructura temporal procesada a partir del MusicXML.

```elixir
%MusicTimeline{
  song_version_id: 1,
  bpm: 120.0,
  total_duration: 32.5
}
```

### `MusicalEvent`

Unidad mínima de sincronización. Representa una nota con su tiempo exacto de inicio y fin.

```elixir
%MusicalEvent{
  music_timeline_id: 1,
  event_type: "note_on",
  pitch: "C4",
  start_time: 0.0,    # segundos
  end_time: 0.5,
  duration: 0.5,
  voice: "melody",
  color_key: "do",    # clave semántica del color
  index: 0            # posición en el pentagrama
}
```

---

## Módulos principales

### `MusicLearning` (contexto público)

```elixir
MusicLearning.list_songs()
MusicLearning.get_song(id)
MusicLearning.list_song_versions(song_id)
MusicLearning.get_musicxml_content(version_id)
MusicLearning.get_timeline_for_version(version_id)

MusicLearning.init_session(session_id, song_id, version_id)
MusicLearning.play(session_id)
MusicLearning.pause(session_id)
MusicLearning.stop(session_id)
MusicLearning.set_speed(session_id, speed)
MusicLearning.note_active(session_id, note_index, current_time)
```

### `SongLibrary`

```elixir
SongLibrary.create_song!(attrs)
SongLibrary.create_song_version!(attrs)
SongLibrary.list_songs()
SongLibrary.get_song_with_versions(id)
```

### `StateModel`

```elixir
StateModel.init_session(session_id, song_id, version_id, events)
StateModel.get_state(session_id)
StateModel.set_playing(session_id, bool)
StateModel.set_position(session_id, seconds)
StateModel.set_speed(session_id, speed)
```

### `SyncEngine`

```elixir
SyncEngine.start_sync(session_id, state)
SyncEngine.pause_sync(session_id)
SyncEngine.stop_sync(session_id)
SyncEngine.note_active(session_id, note_index, current_time)
SyncEngine.tick(session_id, current_time)
```

### `NoteTracker`

Usa ETS para rastrear la nota activa por sesión en tiempo real.

```elixir
NoteTracker.set_active(session_id, note_index)
NoteTracker.get_active(session_id)
NoteTracker.reset(session_id)
NoteTracker.get_active_events(session_id, current_time, events)
NoteTracker.get_upcoming_events(session_id, current_time, events, lookahead_seconds)
```

### `ColorMapper`

```elixir
ColorMapper.get_color_key("C4")    # → "do"
ColorMapper.get_color_key("G#3")   # → "sol"
ColorMapper.get_hex("do")          # → "#E53935"
ColorMapper.all_colors()           # → %{"do" => "#E53935", ...}
```

---

## Sistema de colores

Cada nota tiene un color fijo según su nombre, sin importar la octava. Do3 y Do4 tienen el mismo color.

| Nota | color_key | Hex | Color |
|---|---|---|---|
| Do (C) | `do` | `#E53935` | Rojo |
| Re (D) | `re` | `#FB8C00` | Naranja |
| Mi (E) | `mi` | `#FDD835` | Amarillo |
| Fa (F) | `fa` | `#43A047` | Verde |
| Sol (G) | `sol` | `#1E88E5` | Azul |
| La (A) | `la` | `#8E24AA` | Violeta |
| Si (B) | `si` | `#E91E63` | Rosa |

OSMD aplica los colores usando `coloringMode: 2` (CustomColorSet) con `coloringSetCustom`. El usuario puede desactivar los colores desde la barra de controles — las notas pasan a negro y la nota activa se ilumina con un halo de color.

---

## Reproducción y sincronización

### Flujo de un tick de nota

```
Tone.js Transport
  → Tone.getDraw().schedule(callback, startTime)
    → pushEvent("note_active", { index, color_key, current_time })
      → LiveView handle_event("note_active")
        → NoteTracker.set_active / StateModel.set_position
        → push_event(socket, "highlight_note", %{index, color_key})
          → OsmdHook handleEvent("highlight_note")
            → gNote.getSVGGElement() → nodo SVG vivo
            → setProperty fill + stroke + drop-shadow
```

### Modo blanco y negro

Con colores desactivados, las notas se renderizan en negro via CSS:

```css
.colors-disabled path,
.colors-disabled ellipse {
  fill: black !important;
}
```

La nota activa recibe `fill`, `stroke` y `filter: drop-shadow` con el color de su altura musical, aplicados como inline style con `!important` para sobreescribir la regla CSS.

---

## Rutas

```
GET  /                    Página de inicio
GET  /songs               Lista de canciones (LiveView)
GET  /songs/:id           Reproductor de canción (LiveView)

# Solo en desarrollo
GET  /dev/dashboard       Phoenix LiveDashboard
GET  /dev/mailbox         Previsualizador de correos Swoosh
```

---

## Fase 0 — Validación técnica

Objetivo: probar que el stack puede soportar el producto.

| Paso | Descripción | Estado |
|---|---|---|
| 0.1 | Proyecto Phoenix + Tailwind + página de prueba | ✓ |
| 0.2 | Integrar OSMD — renderizar MusicXML estático | ✓ |
| 0.3 | Cargar MusicXML desde archivos — cambiar entre canciones | ✓ |
| 0.4 | Integrar Tone.js — reproducir notas | ✓ |
| 0.5 | Sincronizar partitura + audio | ✓ |
| 0.6 | Resaltar nota activa | ✓ |
| 0.7 | Controles Play / Pause / Stop | ✓ |
| 0.8 | Control de velocidad | ✓ |
| 0.9 | Sistema de colores por nota | ✓ |
| 0.10 | Demo funcional con "Bartolito" | en progreso |

---

## Tests

```bash
docker compose exec -e MIX_ENV=test app mix test
```

**133 tests — 0 fallos**

| Archivo | Cobertura |
|---|---|
| `song_test.exs` | Changeset de Song: validaciones, campos requeridos |
| `song_version_test.exs` | Changeset de SongVersion: tipos de versión, nivel |
| `musical_event_test.exs` | Changeset de MusicalEvent: pitch, tiempos, color_key |
| `song_library_test.exs` | CRUD de canciones y versiones |
| `color_mapper_test.exs` | Mapeo pitch → color_key → hex, casos borde |
| `notation_config_test.exs` | Configuración de colores OSMD |
| `note_tracker_test.exs` | ETS set/get/reset/seek, aislamiento entre sesiones |
| `state_model_test.exs` | Init, play, pause, set_position, set_speed |
| `audio_sync_test.exs` | Construcción de payloads para Tone.js |
| `musicxml_parser_test.exs` | Parseo de notas, pitches, duraciones desde MusicXML |
| `timeline_builder_test.exs` | Construcción de MusicalEvents desde MusicXML |
| `file_storage_test.exs` | Lectura de archivos MusicXML desde disco |
| `song_live_test.exs` | LiveView: mount, params, controles, eventos de hook |
| `error_html_test.exs` | Páginas de error HTML |
| `error_json_test.exs` | Respuestas de error JSON |
| `page_controller_test.exs` | Página de inicio |

---

## Variables de entorno

### Desarrollo

Configuradas en `config/dev.exs` y via Docker Compose. Por defecto:

- DB: `postgres:postgres@db/music_learning_platform_dev`
- Puerto app: `4000`
- Puerto PostgreSQL (host): `5410`

### Producción

| Variable | Descripción | Requerida |
|---|---|---|
| `DATABASE_URL` | URL completa de PostgreSQL | Sí |
| `SECRET_KEY_BASE` | Clave secreta mínimo 64 caracteres | Sí |
| `PHX_HOST` | Hostname público | Sí |
| `PORT` | Puerto HTTP (default `4000`) | No |
| `POOL_SIZE` | Conexiones al pool de DB (default `10`) | No |

```bash
# Generar SECRET_KEY_BASE
mix phx.gen.secret
```

---

## Docker

El repositorio incluye configuración Docker completa para desarrollo local.

### Archivos

| Archivo | Propósito |
|---|---|
| `Dockerfile.dev` | Imagen de desarrollo con live reload y código montado en volumen |
| `docker-compose.yml` | Orquestación desarrollo: app (4000) + PostgreSQL 16 (5410) |

### Desarrollo con Docker

```bash
# Primera vez
docker compose up --build

# Reinicios posteriores
docker compose up

# Segundo plano
docker compose up -d
```

Abrir [http://localhost:4000](http://localhost:4000).

### Comandos útiles dentro del contenedor

```bash
# Consola IEx interactiva
docker compose exec app iex -S mix

# Tests
docker compose exec -e MIX_ENV=test app mix test

# Seeds (canciones de prueba)
docker compose exec app mix run priv/repo/seeds.exs

# Migraciones
docker compose exec app mix ecto.migrate

# Compilar assets (después de cambios en JS/CSS)
docker compose exec app mix assets.build

# Reiniciar solo la app (sin tocar la DB)
docker compose restart app

# Logs en tiempo real
docker compose logs -f app
```

### Parar y limpiar

```bash
# Parar (datos de DB se conservan)
docker compose down

# Parar y eliminar todos los volúmenes (resetea DB y caché)
docker compose down -v
```

---

## Documentación

```
docs/
├── planned/
│   └── technical/phase_0/     # Diseño técnico antes de implementar
│       ├── 01_Core/
│       ├── 02_Rendering/
│       ├── 03_Audio/
│       ├── 04_Sync/
│       ├── 05_System/
│       └── 06_Testing/
└── implemented/
    └── technical_documentation/   # Lo que ya está construido
        ├── project_setup.md
        ├── dependencies.md
        ├── core_architecture.md
        ├── osmd_integration.md
        ├── audio_playback.md
        ├── musicxml_integration.md
        ├── note_color_system.md
        ├── color_mapping_system.md
        └── active_note_highlight.md
```

---

## Ramas y commits

```
main        ← producción, solo merge via PR
feature/*   ← nuevas funcionalidades
fix/*       ← correcciones de bugs
chore/*     ← mantenimiento
docs/*      ← documentación
```

Formato de commits (Conventional Commits):

```
feat: descripción
fix: descripción
refactor: descripción
test: descripción
docs: descripción
chore: descripción
```

---

## Decisiones de diseño

| Decisión | Razón |
|---|---|
| Backend no reproduce audio | Latencia de red hace imposible la sincronización precisa desde el servidor |
| Tone.js como única fuente de audio | API Web Audio de alta precisión; ninguna otra librería puede sincronizarse con el Transport scheduler |
| Todo sync pasa por Sync Engine | Centraliza la lógica de timing; OSMD nunca habla directamente con Tone.js |
| JS Bridge obligatorio | Separa responsabilidades entre LiveView (estado) y motores JS (audio + visual) |
| Workers para procesamiento MusicXML | Parsear XML es costoso; nunca dentro de mount o handle_event |
| `coloringMode: 2` en OSMD | CustomColorSet es la única API pública que permite colores arbitrarios por nota sin parchear la librería |
| CSS `.colors-disabled` con `!important` | El toggle de colores necesita sobreescribir los estilos inline que OSMD aplica al renderizar |
| `autoResize: false` en OSMD | Con `true`, LiveView DOM patches provocan un re-render de OSMD que invalida las referencias a nodos SVG almacenadas para el highlight |
| ETS para NoteTracker | Acceso en microsegundos sin bloquear el proceso de LiveView; el estado de nota activa cambia en cada tick de audio |
| `resolveHex()` en el frontend | La DB contiene `color_key` en formato hex legado (`#FF4444`) del seed anterior al sistema semántico; se normaliza en JS sin migración de datos |
