# Reproducción de Audio — Tone.js

## ¿Qué hace el sistema?

Reproduce las notas de una canción directamente en el navegador usando Tone.js.
El usuario puede iniciar, pausar, detener y cambiar la velocidad de reproducción.
Cada nota que suena dispara un evento de highlight hacia el hook OSMD para sincronizar audio y partitura.

---

## ¿Cómo está construido?

### Archivos

```
assets/js/
└── tone_player_hook.js                        ← Hook Tone.js: programa y reproduce notas

lib/music_learning_platform/
├── application/playback/
│   ├── audio_sync.ex                          ← Construye los payloads para el JS Bridge
│   ├── playback_controller.ex                 ← Comandos play/pause/stop/seek
│   └── tempo_controller.ex                    ← Control de velocidad (0.5x – 2.0x)
└── music_learning.ex                          ← get_timeline_for_version/1 añadido

lib/music_learning_platform_web/
└── live/song_live/
    └── show.ex                                ← Controles UI + 7 event handlers nuevos
```

---

## ¿Cómo funciona internamente?

### Flujo de Play

```
Usuario hace clic en Play
        ↓
LiveView handle_event("play")
        ↓
MusicLearning.play(session_id)
        ↓
PlaybackController → StateModel.set_playing(true)
        ↓
AudioSync.build_play_payload(state, bpm_base)
  → bpm efectivo = bpm_base × speed
  → filtra eventos note_on con pitch válido
  → serializa {pitch, start_time, duration, index, color_key}
        ↓
push_event("tone_play", payload)
        ↓
TonePlayerHook.play({ bpm, speed, current_time, events })
  → await Tone.start()
  → new Tone.PolySynth(Tone.Synth)
  → escala tiempos: transport_time = start_time / speed
  → new Tone.Part → schedules cada nota
  → Tone.getDraw().schedule → pushEvent("tone_note_on", {index, color_key})
  → Tone.getTransport().start("+0.1", offset)
        ↓
LiveView handle_event("tone_note_on")
        ↓
push_event("highlight_note", {index, color_key})
        ↓
OsmdHook.highlightNote(index, color_key)
```

### Flujo de Stop

```
Usuario hace clic en Stop
        ↓
LiveView handle_event("stop")
        ↓
MusicLearning.stop(session_id)       ← resetea ETS: current_time=0, is_playing=false
        ↓
push_event("tone_stop", %{})
        ↓
TonePlayerHook.stop()
  → Tone.getTransport().stop()
  → transport.position = 0
  → part.dispose()
  → pushEvent("tone_stopped", {})
        ↓
LiveView handle_event("tone_stopped")
        ↓
assign(is_playing: false, current_time: 0.0)
```

### Control de velocidad

```
Usuario selecciona 0.5x
        ↓
LiveView handle_event("set_speed", %{"speed" => "0.5"})
        ↓
MusicLearning.set_speed(session_id, 0.5)
        ↓
AudioSync.build_tempo_payload(state, bpm_base)
  → payload incluye speed, bpm escalado, current_time y eventos
        ↓
push_event("tone_set_tempo", payload)
        ↓
TonePlayerHook.setTempo(payload)
  → llama play() con los nuevos parámetros (reconstruye el schedule)
```

### Escalado de tiempos

Los `start_time` del EventTimeline están en segundos a velocidad base (1.0).
Para aplicar el factor de velocidad:

```
transport_time = start_time / speed
transport_duration = duration / speed
```

No se modifica `Tone.Transport.bpm` — el Transport corre a tiempo real y los tiempos se escalan manualmente al programar el `Tone.Part`.

---

## Eventos LiveView ↔ TonePlayerHook

| Dirección | Evento | Payload | Acción |
|---|---|---|---|
| LiveView → Hook | `tone_play` | `{bpm, speed, current_time, events}` | Programa y reproduce todas las notas |
| LiveView → Hook | `tone_pause` | `{current_time}` | Pausa el Transport |
| LiveView → Hook | `tone_stop` | `{}` | Detiene y resetea el Transport |
| LiveView → Hook | `tone_set_tempo` | `{bpm, speed, current_time, events}` | Reconstruye schedule con nueva velocidad |
| Hook → LiveView | `tone_note_on` | `{index, color_key}` | Indica qué nota está sonando |
| Hook → LiveView | `tone_stopped` | `{}` | Confirma que el audio se detuvo |

---

## Sesión de reproducción

Cada instancia de LiveView genera un `session_id` único en `mount`:

```elixir
session_id = "session_#{System.unique_integer([:positive])}"
```

El estado se guarda en ETS (`StateModel`) con los campos:

| Campo | Tipo | Descripción |
|---|---|---|
| `current_time` | float | Posición en segundos |
| `is_playing` | boolean | Estado actual |
| `speed` | float | Factor de velocidad (0.5 – 2.0) |
| `events` | list | Eventos musicales cargados desde DB |

La sesión se inicializa en `handle_params` cuando se navega a una canción.
Se reinicializa al cambiar de canción o de versión.

---

## Controles de reproducción

La barra de controles aparece solo cuando existe un `MusicTimeline` para la versión seleccionada (`timeline_loaded: true`).

| Control | Velocidades disponibles |
|---|---|
| Play / Pause (toggle) | — |
| Stop | — |
| Velocidad | 0.5x · 0.75x · 1x · 1.5x · 2x |

La velocidad activa se resalta con `btn-primary`. El botón Play cambia a Pause mientras el audio está activo.

---

## Restricción crítica

El audio nunca se controla directamente desde LiveView.
El flujo siempre es: **LiveView → AudioSync → push_event → TonePlayerHook → Tone.js**.

`AudioSync` es el único módulo que construye payloads para el JS Bridge.
`PlaybackController` es el único módulo que modifica el estado de sesión.

---

## Requisito de browser

Los navegadores bloquean el `AudioContext` hasta que el usuario interactúa con la página.
`app.js` registra un listener de un solo uso para desbloquearlo:

```js
document.addEventListener("click", () => Tone.start(), { once: true })
```

Esto garantiza que el AudioContext esté activo antes de que llegue el evento `tone_play` desde el servidor.
