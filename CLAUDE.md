# CLAUDE.md — Music Learning Platform

## Project
Web platform for learning piano using a color-coded sheet music system.
Target users: children and beginners with zero music theory.
Core value: colored notation + progressive levels per song.

## Tech Stack
- Language: Elixir 1.19.5
- Framework: Phoenix 1.8.5
- UI / Realtime: Phoenix LiveView 1.1
- Audio engine: Tone.js (JavaScript)
- Score renderer: OpenSheetMusicDisplay (OSMD)
- Music format: MusicXML (primary), MIDI (future)
- Database: PostgreSQL 16.14
- CSS: Tailwind v4 + DaisyUI
- Icons: Heroicons v2.2
- Image storage: Cloudflare R2
- HTTP server: Bandit

## Architecture — Mental Model
```
MusicXML → Workers → Event Timeline → Sync Engine → State Model
                                                          ↓
                                                      LiveView
                                                          ↓
                                                      JS Bridge
                                                     ↙        ↘
                                                 OSMD       Tone.js
```

Backend does NOT play audio or render music — it only coordinates.

## Layer Responsibilities
- State Model: runtime source of truth (active song, level, play/pause, tempo)
- Event Timeline: MusicXML → timed events — the musical source of truth
- Sync Engine: keeps audio + visual in sync against the timeline
- JS Bridge (hooks): LiveView ↔ OSMD/Tone.js communication
- Workers: async MusicXML processing, level generation, normalization
- OSMD: SVG score rendering + note highlight
- Tone.js: audio playback, Transport scheduler, BPM control

## Code Structure
```
lib/
├── music_learning/
│   ├── state/       # state_model.ex, playback_state.ex, session_state.ex
│   ├── sync/        # sync_engine.ex, time_coordinator.ex, note_tracker.ex
│   ├── timeline/    # event_timeline.ex, musicxml_parser.ex, timeline_builder.ex
│   ├── songs/       # song.ex, level.ex, song_library.ex, song_loader.ex
│   ├── workers/     # musicxml_worker.ex, level_generator_worker.ex
│   ├── playback/    # playback_controller.ex, tempo_controller.ex, audio_sync.ex
│   └── visual/      # color_mapper.ex, notation_config.ex, highlight_engine.ex
└── music_learning_web/
    ├── live/song_live/  # show.ex, controls_component.ex, score_component.ex
    ├── hooks/           # osmd_hook.js, tone_player_hook.js, sync_hook.js
    └── router.ex
```

## Core Entities
- Song: base entity (title, category, duration)
- SongVersion: pedagogical level (melody | simplified | chords | full)
- MusicTimeline: processed temporal structure (bpm, total_duration, resolution)
- MusicalEvent: minimum sync unit (pitch, start_time, end_time, voice, color_key)
- PlaybackSession: real-time playback state (current_time, is_playing, speed)
- ContentAsset: files associated to a song (musicxml | audio | image | midi)

## Phase 0 — Technical Validation (current)
Goal: prove the stack can support the product.

- 0.1 Phoenix project + Tailwind + test page
- 0.2 Integrate OSMD — render static MusicXML
- 0.3 Load MusicXML from files — switch between songs
- 0.4 Integrate Tone.js — play notes
- 0.5 Sync score + audio  ← highest risk
- 0.6 Highlight current note
- 0.7 Play / Pause / Stop controls
- 0.8 Speed control
- 0.9 Color system per note
- 0.10 Functional demo with "Bartolito"

## Critical Rules
- Musical timing logic belongs in Event Timeline, never in LiveView
- Tone.js is the only audio source — no other audio APIs
- All sync goes through Sync Engine — OSMD never talks directly to Tone.js
- JS Bridge (hooks) is the mandatory bridge between LiveView and JS engines
- Workers handle heavy processing — never inside mount or handle_event

------------------------------------------------------------

## Token Optimization (IMPORTANT)

- Respond only in English.
- Do not mix languages.
- Be concise and direct.
- Do not generate long summaries after tasks.
- Do not explain code unless explicitly requested.
- Do not describe obvious implementation details.
- Do not repeat information already mentioned.
- Do not restate requirements.
- Do not use tables unless strictly necessary.
- Avoid sections like "What was done", "Summary", etc.

### Task Completion Format

When finished, respond ONLY with:
- Status (completed/pending + short summary)
- Modified files
- Tests added/modified
- Test results

### Code Analysis Rules

- Read only necessary files
- Avoid full repo scans
- Avoid global searches unless needed
- Do not inspect unrelated modules
- Reuse existing context

### Information Requests

- Ask specific questions
- Request specific files
- Avoid directory-wide analysis

### Objective

Minimize token usage while maintaining correctness and implementation quality.
