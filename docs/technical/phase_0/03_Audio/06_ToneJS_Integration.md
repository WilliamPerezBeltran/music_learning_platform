# 06 — Integración Tone.js

## Rol
Tone.js es el único motor de audio de la plataforma.
Maneja toda la producción de sonido, programación de notas, control de tempo y precisión de tiempo.

Tone.js nunca controla el estado visual — solo produce sonido.
Toda la coordinación visual es responsabilidad del Sync Engine.

---

## Integración

Tone.js vive completamente en JavaScript.
Se conecta a Phoenix LiveView a través del JS Bridge.

```
LiveView (Elixir)
    ↓  pushEvent
tone_player_hook.js  (JS Bridge)
    ↓
Tone.js Transport + Synth API
    ↓
Salida de audio del navegador
```

El hook se monta en el elemento contenedor del reproductor:
```html
<div id="player" phx-hook="TonePlayerHook"></div>
```

---

## Eventos

Eventos recibidos desde LiveView vía `pushEvent`:

| Evento | Payload | Acción |
|---|---|---|
| `play` | `{ current_time: T, bpm: B }` | Inicia el Transport desde T con BPM B |
| `pause` | `{}` | Suspende el Transport, conserva posición |
| `stop` | `{}` | Detiene y resetea el Transport a 0 |
| `set_speed` | `{ bpm: B }` | Actualiza el BPM del Transport |
| `load_events` | `{ events: [...] }` | Carga los MusicalEvents en el scheduler |

---

## Programación de Notas

En `load_events`, el hook programa todos los MusicalEvents en Tone.Transport:

```javascript
events.forEach(event => {
  Tone.Transport.schedule(time => {
    synth.triggerAttackRelease(event.pitch, event.duration, time)
    // notifica a LiveView para resaltar la nota
    pushEventTo(target, "note_active", { index: event.index })
  }, event.start_time)
})
```

Cada callback programado:
1. Reproduce la nota vía `Tone.Synth`
2. Notifica a LiveView para disparar el evento de highlight en OSMD

---

## Control del Transport

El Transport de Tone.js es el reloj maestro para toda la programación de audio.

```
Tone.Transport.bpm.value = bpm_efectivo
Tone.Transport.start()   // play
Tone.Transport.pause()   // pause
Tone.Transport.stop()    // stop + reset
Tone.Transport.seconds   // posición actual
```

Los cambios de velocidad se aplican actualizando `bpm.value` — los eventos programados se ajustan automáticamente.

---

## Sintetizador

La Fase 0 usa un `Tone.Synth` básico (monofónico, forma de onda simple).
Sin instrumentos sampleados, sin soundfonts MIDI — se valida primero con audio sintético.

Futuro: reemplazar con `Tone.Sampler` + samples de piano para reproducción realista.

---

## Restricción Crítica

Tone.js nunca se comunica con OSMD directamente.
El callback de nota notifica a LiveView, que luego envía un evento `highlight_note` a `osmd_hook.js`.

Razón: mantener Tone.js y OSMD desacoplados permite controlar de forma independiente las capas de audio y visual,
y conserva el Sync Engine como único coordinador.

---

## Hitos Fase 0

| Paso | Tarea |
|---|---|
| 0.4 | Integrar Tone.js — reproducir notas desde el Event Timeline |
| 0.5 | Sincronizar partitura + audio vía callbacks del Transport |
| 0.8 | Control de velocidad vía BPM del Transport |
