# 10 — Arquitectura de JS Hooks

## Rol
Los JS Hooks son el puente obligatorio entre Phoenix LiveView (Elixir) y los motores JavaScript (OSMD, Tone.js).

LiveView no puede llamar JavaScript directamente.
Los hooks son el único canal de comunicación entre el backend y los motores del frontend.

---

## Por Qué Existen

Phoenix LiveView gestiona el DOM desde el servidor.
OSMD y Tone.js viven completamente en el navegador y requieren APIs JavaScript nativas.

Sin los hooks, LiveView no puede:
- Indicarle a OSMD que renderice una partitura
- Indicarle a Tone.js que reproduzca una nota
- Recibir callbacks de timing del Transport

---

## Los Tres Hooks

### `osmd_hook.js`
Gestiona el ciclo de vida de OpenSheetMusicDisplay.

Responsabilidades:
- Inicializar OSMD sobre el elemento DOM
- Cargar y renderizar el MusicXML en SVG
- Aplicar clases CSS de color a las notas
- Resaltar la nota activa durante la reproducción
- Limpiar highlights al pausar o detener

### `tone_player_hook.js`
Gestiona el ciclo de vida del motor de audio Tone.js.

Responsabilidades:
- Inicializar Tone.Synth y Tone.Transport
- Cargar los MusicalEvents en el scheduler
- Controlar play / pause / stop del Transport
- Ajustar BPM para control de velocidad
- Emitir evento `note_active` a LiveView en cada nota programada

### `sync_hook.js`
Coordina la sincronización entre los dos hooks anteriores.

Responsabilidades:
- Recibir el estado global de reproducción desde LiveView
- Propagar cambios de estado a `osmd_hook.js` y `tone_player_hook.js`
- Garantizar que audio y visual respondan al mismo evento de control

---

## Ciclo de Vida de un Hook

```javascript
const OsmdHook = {
  mounted() {
    // inicializar OSMD sobre this.el
  },
  handleEvent("load_score", ({ musicxml }) => {
    // renderizar partitura
  }),
  handleEvent("highlight_note", ({ index, color_key }) => {
    // resaltar nota en SVG
  }),
  destroyed() {
    // limpiar instancia OSMD
  }
}
```

El mismo patrón aplica para `tone_player_hook.js` y `sync_hook.js`.

---

## Registro de Hooks

Los hooks se registran en el archivo de entrada JavaScript antes de conectar el socket de LiveView:

```javascript
// music_learning_web.js
import { OsmdHook } from "./hooks/osmd_hook"
import { TonePlayerHook } from "./hooks/tone_player_hook"
import { SyncHook } from "./hooks/sync_hook"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { OsmdHook, TonePlayerHook, SyncHook }
})
```

---

## Montaje en Templates

Cada hook se asocia a un elemento DOM vía `phx-hook`:

```html
<div id="score-container" phx-hook="OsmdHook"></div>
<div id="player"          phx-hook="TonePlayerHook"></div>
<div id="sync-controller" phx-hook="SyncHook"></div>
```

El `id` es obligatorio cuando se usa `phx-hook`.

---

## Flujo de Comunicación

```
LiveView
  ↓  push_event("load_score", %{musicxml: xml})
osmd_hook.js
  ↓  OSMD.load(xml) → renderiza SVG

LiveView
  ↓  push_event("play", %{bpm: B, current_time: T})
tone_player_hook.js
  ↓  Transport.start()
  ↓  en cada nota: pushEventTo(LiveView, "note_active", {index: N})

LiveView
  ↓  push_event("highlight_note", %{index: N, color_key: key})
osmd_hook.js
  ↓  aplica clase CSS activa sobre nota SVG
```

---

## Restricciones

- Los hooks nunca se comunican directamente entre sí — todo pasa por LiveView
- OSMD Hook no conoce a Tone.js Hook y viceversa
- El estado de reproducción siempre es gestionado por el backend, no por los hooks

---

## Hitos Fase 0

| Paso | Tarea |
|---|---|
| 0.2 | `osmd_hook.js` — renderizar MusicXML estático |
| 0.4 | `tone_player_hook.js` — reproducir notas |
| 0.5 | `sync_hook.js` — sincronizar partitura + audio |
