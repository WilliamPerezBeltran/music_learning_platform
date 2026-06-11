# 04 — OpenSheetMusicDisplay (OSMD)

## Role
OSMD is the score rendering engine.
It takes a MusicXML file and renders it as an interactive SVG in the browser.

OSMD is responsible for:
- Rendering the score (staff, notes, clef, time signature)
- Highlighting the active note during playback
- Applying note colors from the color system

OSMD is a pure visual layer — it has no timing logic and no audio.

---

## Integration

OSMD lives entirely in JavaScript.
It is connected to Phoenix LiveView through the JS Bridge layer using a Phoenix hook.

```
LiveView (Elixir)
    ↓  pushEvent / handle_event
osmd_hook.js  (JS Bridge)
    ↓
OSMD JavaScript API
    ↓
SVG rendered in DOM
```

The hook is mounted on the score container element:
```html
<div id="score-container" phx-hook="OsmdHook"></div>
```

`osmd_hook.js` is registered in the LiveView hooks bootstrap (`music_learning_web.js`).

---

## Events

Events sent from LiveView to the hook via `pushEvent`:

| Event | Payload | Action |
|---|---|---|
| `load_score` | `{ musicxml: "..." }` | Initialize OSMD, render the score |
| `highlight_note` | `{ index: N, color_key: "..." }` | Highlight note at position N |
| `clear_highlight` | `{}` | Remove all active highlights |

Events sent from the hook back to LiveView via `pushEventTo` (future):

| Event | Payload | Purpose |
|---|---|---|
| `score_loaded` | `{ total_notes: N }` | Confirm render complete |
| `note_clicked` | `{ index: N }` | User clicked a note (future) |

---

## Note Highlighting

During playback, the Sync Engine emits a `highlight_note` event for each active MusicalEvent.
The hook translates this into an OSMD API call that marks the SVG note element as active.

Flow:
```
Sync Engine fires event at start_time
    ↓
LiveView receives timing callback
    ↓
pushEvent("highlight_note", %{index: N, color_key: key})
    ↓
osmd_hook.js calls OSMD cursor / graphic note API
    ↓
SVG note element gets active CSS class
```

---

## Color System

Each note has a `color_key` derived from its pitch step (C, D, E, F, G, A, B).
`color_mapper.ex` defines the mapping.

In the SVG, colors are applied as CSS classes on the note element:

```
color_key "do"  → CSS class .note-do  → fill: #E53935
color_key "re"  → CSS class .note-re  → fill: #FB8C00
color_key "mi"  → CSS class .note-mi  → fill: #FDD835
color_key "fa"  → CSS class .note-fa  → fill: #43A047
color_key "sol" → CSS class .note-sol → fill: #1E88E5
color_key "la"  → CSS class .note-la  → fill: #8E24AA
color_key "si"  → CSS class .note-si  → fill: #E91E63
```

Colors are applied on `load_score` — all notes get their color class at render time.
The active/highlight state is a separate CSS class layered on top.

---

## Critical Constraint

OSMD never communicates with Tone.js directly.
All coordination goes through: Sync Engine → LiveView → JS Bridge → OSMD.

Reason: direct coupling between OSMD and Tone.js would bypass the Sync Engine,
breaking the single source of truth for timing.

---

## Phase 0 Milestones

| Step | Task |
|---|---|
| 0.2 | Integrate OSMD — render a static MusicXML file |
| 0.3 | Switch between songs — reload OSMD with different MusicXML |
| 0.6 | Highlight current note during playback |
| 0.9 | Apply color system to all notes in the score |
