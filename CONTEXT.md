# CONTEXT.md — Music Learning Platform

## Vision
Educational platform for learning piano through a color-based visual system.
Children and beginners can play songs quickly without prior music knowledge.

Core combination:
- Colored sheet music
- Interactive playback
- Progressive levels per song
- Guided tutorials
- Freemium model

## Business Model
- Free: first songs, first levels, basic features
- Premium: full library, all levels, weekly new songs, progress tracking, PDF export

## MVP Validation Hypothesis
A user with zero music knowledge can:
1. Choose a song
2. Follow the color-coded score
3. Listen to the playback
4. Learn a basic melody
5. Progress through levels faster than with traditional notation

## Phase Roadmap (high level)
- Phase 0: Technical validation — prove the stack works
- Phase 1: MVP Core — library, colored score, playback, visual config
- Phase 2: Level system — 5 difficulty levels per song
- Phase 3: Content admin — add songs without code changes
- Phase 4: Initial catalog — 20–50 songs, beta launch
- Phase 5: Landing page — acquisition
- Phase 6: User accounts — persist progress
- Phase 7: Progress tracking — metrics per song/level
- Phase 8: Monetization — first paying users
- Phase 9: Social media content — organic acquisition funnel
- Phase 10: Advanced features — virtual piano, MIDI input, evaluation
- Phase 11: AI — audio→MusicXML, auto level generation (only after market validation)

## Level System (per song)
```
Level 1 — Main melody only
Level 2 — Simplified melody
Level 3 — Melody + basic chords
Level 4 — Simplified left hand
Level 5 — Full song
```

## Initial Song Catalog (Phase 0 test songs)
- Bartolito (primary demo)
- Estrellita
- Feliz Cumpleaños
- Los Pollitos
- Himno de la Alegría

Each song needs: MusicXML file, lyrics, note colors, available levels.

## Visual Configuration (user-controlled toggles)
- Colors on/off
- Note names (Do, Re, Mi...) on/off
- Chords on/off
- Left hand on/off
- Right hand on/off
- Lyrics on/off

## Data Model
See `docs/technical/phase_0/01_Core/entities.md` for full field definitions.

Relationships:
```
Song
 └── SongVersion (1→N)   — one version per difficulty level
      └── MusicTimeline (1→1)  — processed temporal data
           └── MusicalEvent (1→N)  — individual note/rest events

Song
 └── ContentAsset (1→N)  — MusicXML, audio, image, MIDI files

PlaybackSession — tracks current runtime state per session
User (future) → UserProgress (future)
```

## Architecture Layers
See `docs/technical/phase_0/01_Core/architecture.md` for full diagram.

```
[ USER BROWSER ]
  Phoenix LiveView (UI)
       ↕ JS Bridge (hooks)
  OSMD (score SVG)   Tone.js (audio)
       ↕ LiveView events
[ BACKEND ]
  State Model → Sync Engine → Event Timeline → Workers
```

Full code structure mapped in:
`docs/technical/phase_0/01_Core/architecture_mapping_and_system_flow_phoenix.md`

## MusicXML File Storage
Decision pending. Options evaluated:
- `priv/static/` — simplest for Phase 0
- S3 / Cloudflare R2 — for production scale
- Git repository — for versioning during development

Recommended for Phase 0: `priv/static/songs/`

## Color Mapping System
One color per musical note (Do→Re→Mi... mapped to distinct colors).
Color applied to: note head in SVG, note name label, highlight overlay during playback.
Mapping defined in `color_mapper.ex` (Visual layer).

## Synchronization Strategy
Highest technical risk of Phase 0.

The sync problem: MusicXML defines notes structurally, Tone.js plays in real time,
OSMD renders statically. The three must stay aligned during playback.

Solution architecture:
- MusicXML is parsed once into an Event Timeline (list of timed events)
- Tone.js Transport fires callbacks at each event's start_time
- Each callback triggers: audio note play + OSMD highlight update
- Seeking/pause handled by resetting Transport position against the timeline

All sync goes through the Sync Engine — OSMD and Tone.js never communicate directly.

## JS Hooks Architecture
LiveView cannot call JavaScript directly. The bridge:
```
LiveView
  ↓ pushEvent / handle_event
JS Hook (osmd_hook.js | tone_player_hook.js | sync_hook.js)
  ↓
OSMD / Tone.js
```

Hooks are mounted on DOM elements via `phx-hook` attribute.
They receive events from LiveView and translate them to JS engine calls.

## Current Status (Phase 0)
- Documentation: business layer complete, architecture complete, implementation docs mostly empty stubs
- Code: no Phoenix project created yet
- Next step: 0.1 — create Phoenix project
