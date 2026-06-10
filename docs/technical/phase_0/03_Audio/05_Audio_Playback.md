# 05 — Reproducción de Audio

## Rol
El sistema de reproducción controla el ciclo de vida de la canción:
iniciar, pausar, detener, buscar posición y ajustar velocidad.

Actúa como capa de comandos entre las acciones del usuario en LiveView y Tone.js.
No produce sonido directamente — emite comandos a Tone.js a través del JS Bridge.

---

## Controles de Reproducción

| Control | Acción |
|---|---|
| Play | Inicia el Transport de Tone.js desde la posición actual |
| Pause | Suspende el Transport, conserva el current_time |
| Stop | Resetea el Transport a 0, limpia el highlight |
| Velocidad | Ajusta el multiplicador de BPM en el Transport de Tone.js |

---

## Módulos Backend

### `playback_controller.ex`
Maneja los comandos play / pause / stop desde LiveView.
Actualiza el estado de `PlaybackSession`.
Emite eventos JS a través de `audio_sync.ex`.

### `tempo_controller.ex`
Gestiona el factor de velocidad (0.5x – 2.0x).
Traduce el factor de velocidad a BPM para el Transport de Tone.js.

### `audio_sync.ex`
Coordina el estado entre el backend y el JS Bridge.
Envía llamadas `pushEvent` a `tone_player_hook.js`.

---

## PlaybackSession
Entidad de estado en tiempo real — una por sesión de usuario activa.

```
current_time   — float, segundos desde el inicio de la canción
is_playing     — boolean
speed          — float (0.5 – 2.0)
loop_enabled   — boolean
started_at     — datetime
paused_at      — datetime
client_id      — identificador de sesión del navegador
```

El estado se actualiza en cada acción de play / pause / stop / seek.

---

## Flujo de Reproducción

```
Usuario hace clic en Play
    ↓
LiveView handle_event("play")
    ↓
playback_controller.ex actualiza PlaybackSession
    ↓
audio_sync.ex pushEvent("play", %{current_time: T, bpm: B})
    ↓
tone_player_hook.js inicia Tone.Transport
    ↓
Tone.js programa las notas desde current_time
    ↓
Sync Engine dispara eventos highlight_note por nota
```

---

## Control de Velocidad

La velocidad es un multiplicador aplicado al BPM base del MusicTimeline.

```
bpm_base = MusicTimeline.bpm
bpm_efectivo = bpm_base * factor_velocidad
```

`tempo_controller.ex` calcula el `bpm_efectivo` y lo envía al Transport de Tone.js.
Los start_times del Event Timeline son fijos — solo cambia la tasa de reproducción.

---

## Restricción Crítica

Los comandos de reproducción siempre pasan por `playback_controller.ex`.
LiveView nunca llama a Tone.js directamente — siempre a través de `audio_sync.ex` → JS Bridge.

---

## Hitos Fase 0

| Paso | Tarea |
|---|---|
| 0.4 | Integrar Tone.js — reproducir notas |
| 0.7 | Controles Play / Pause / Stop |
| 0.8 | Control de velocidad |
