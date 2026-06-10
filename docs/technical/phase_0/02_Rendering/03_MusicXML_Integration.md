# 03 — MusicXML Integration

## Role
MusicXML is the primary music format of the platform.
It is the entry point of the entire musical pipeline:
from static file to Event Timeline used by the Sync Engine.

MusicXML is never rendered directly to the user — it is parsed into
structured MusicalEvents that drive both audio and visual layers.

---

## Storage

Location: `priv/static/songs/`

```
priv/
└── static/
    └── songs/
        ├── bartolito_level1.xml
        ├── bartolito_level2.xml
        └── estrellita_level1.xml
```

One file per SongVersion (one per difficulty level).
File naming convention: `{song_slug}_level{n}.xml`

Phase 0 decision: local static storage.
Production path: S3 / Cloudflare R2 (future).

---

## Processing Pipeline

```
priv/static/songs/{file}.xml
        ↓
   song_loader.ex          — reads file from disk, associates to SongVersion
        ↓
  musicxml_worker.ex       — async worker, triggers processing pipeline
        ↓
  musicxml_parser.ex       — parses XML structure, extracts raw note data
        ↓
  timeline_builder.ex      — converts raw notes into timed MusicalEvents
        ↓
  MusicTimeline            — stored result: bpm, total_duration, resolution
        ↓
  MusicalEvent[]           — list of timed events ready for Sync Engine
```

---

## What Gets Extracted

From each MusicXML note element, the parser extracts:

| Field | Source in MusicXML | Description |
|---|---|---|
| pitch | `<pitch>` step + octave | e.g. C4, D4, E4 |
| start_time | cumulative duration offset | seconds from song start |
| end_time | start_time + duration | seconds |
| duration | `<duration>` + divisions | float seconds |
| voice | `<voice>` + staff number | melody / left_hand / right_hand |
| color_key | derived from pitch step | maps to color system (Do→red, etc.) |

Each extracted note becomes one `MusicalEvent` record.
All events for a SongVersion are grouped into one `MusicTimeline`.

---

## Output Structures

### MusicTimeline
```
bpm             — beats per minute from MusicXML <tempo>
total_duration  — total song length in seconds
resolution      — tick precision (from MusicXML divisions)
source_format   — "musicxml"
```

### MusicalEvent
```
event_type   — note_on | note_off | chord | rest
pitch        — C4, D4, E4 ...
start_time   — float (seconds)
end_time     — float (seconds)
duration     — float (seconds)
velocity     — 0–127 (optional)
voice        — melody | left_hand | right_hand
color_key    — string key used by color_mapper.ex
index        — sequential order
```

---

## Critical Constraint

MusicXML parsing must never happen inside a LiveView `mount` or `handle_event`.

All parsing and timeline building is handled exclusively by `musicxml_worker.ex`.
Workers are triggered asynchronously after file upload or on first song load.

Reason: parsing is CPU-intensive and would block the LiveView process,
causing latency or crashes under concurrent users.

---

## Phase 0 Scope

Steps covered by this document:

- **0.3** — Load MusicXML from files, switch between songs
