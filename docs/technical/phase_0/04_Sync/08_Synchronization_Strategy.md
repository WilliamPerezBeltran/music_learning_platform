# 08 — Estrategia de Sincronización

## Riesgo Principal
La sincronización partitura ↔ audio es el mayor riesgo técnico de la Fase 0.

Si no se logra sincronizar correctamente MusicXML, OSMD y Tone.js,
el producto completo se vuelve inviable.

---

## El Problema

Tres sistemas con naturalezas distintas deben mantenerse alineados durante la reproducción:

| Sistema | Naturaleza |
|---|---|
| MusicXML | Estructura musical estática (notas, duraciones, compases) |
| Tone.js | Reproductor en tiempo real (Transport con reloj interno) |
| OSMD | Renderizado SVG estático (no tiene reloj propio) |

MusicXML no sabe nada de tiempo real.
OSMD no sabe cuándo está sonando cada nota.
Tone.js no sabe qué nota visual debe resaltar.

---

## Solución: Event Timeline como Fuente de Verdad

El MusicXML se parsea una sola vez y se convierte en una lista de MusicalEvents con tiempos absolutos en segundos.

```
MusicXML
    ↓
musicxml_parser.ex + timeline_builder.ex
    ↓
MusicTimeline { bpm, total_duration }
    ↓
MusicalEvent[] { pitch, start_time, end_time, voice, color_key }
```

Todos los sistemas sincronizan contra esta timeline — no entre sí.

---

## Flujo de Sincronización

```
load_events enviado a tone_player_hook.js
    ↓
Tone.Transport.schedule() programa cada nota en su start_time
    ↓
Usuario presiona Play
    ↓
Transport inicia — reloj corre
    ↓
En cada start_time:
  ├── Tone.Synth reproduce la nota  (audio)
  └── pushEventTo LiveView: "note_active" { index: N }
         ↓
      LiveView handle_info
         ↓
      pushEvent a osmd_hook.js: "highlight_note" { index: N, color_key: key }
         ↓
      OSMD marca la nota SVG como activa  (visual)
```

---

## Manejo de Pause y Seek

### Pause
```
Transport.pause()  →  congela el reloj interno
current_time guardado en PlaybackSession
```

### Resume
```
Transport.start() desde Transport.seconds actual
Los eventos futuros se ejecutan normalmente
```

### Seek (futuro)
```
Transport.stop()
Transport.seconds = nueva_posición
Reprogramar eventos desde nueva_posición
Transport.start()
```

---

## Módulos Involucrados

| Módulo | Responsabilidad |
|---|---|
| `sync_engine.ex` | Orquestador principal del proceso de sync |
| `time_coordinator.ex` | Gestiona la posición temporal durante play/pause/seek |
| `note_tracker.ex` | Lleva el registro de la nota activa actual |
| `tone_player_hook.js` | Programa eventos en Tone.Transport, emite callbacks |
| `osmd_hook.js` | Recibe eventos de highlight, aplica clase CSS en SVG |

---

## Restricciones Críticas

- OSMD y Tone.js nunca se comunican directamente
- El Sync Engine es el único coordinador entre audio y visual
- Los start_times del Event Timeline son la referencia de tiempo — nunca el DOM ni OSMD

---

## Hitos Fase 0

| Paso | Tarea |
|---|---|
| 0.5 | Sincronizar partitura + audio — validación core del sistema |
| 0.6 | Highlight de nota activa durante la reproducción |
