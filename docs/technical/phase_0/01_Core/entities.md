# Music Learning Platform — Entities (Core Data Model)

---

# 1. Song

Representa una canción dentro del sistema.

## Propósito
Entidad base del sistema musical.

## Campos

- id
- title
- artist (opcional)
- category
- description (opcional)
- duration_seconds
- thumbnail_url (opcional)
- is_published (boolean)
- metadata (jsonb opcional)
- inserted_at
- updated_at

## Relaciones

- Song 1 → N SongVersion
- Song 1 → N ContentAsset

---

# 2. SongVersion

Representa una versión pedagógica o nivel de dificultad de una canción.

## Propósito
Define los niveles progresivos de aprendizaje.

## Campos

- id
- song_id (FK → Song)
- version_type (melody | simplified | chords | full | custom)
- level_index
- name
- description (opcional)
- musicxml_path
- difficulty_score (0–100)
- hand_config (jsonb)
- visibility_config (jsonb)
- is_active (boolean)
- inserted_at
- updated_at

## Relaciones

- SongVersion 1 → 1 MusicTimeline

---

# 3. MusicTimeline

Representa la estructura temporal procesada de una canción.

## Propósito
Base para la sincronización musical en tiempo real.

## Campos

- id
- song_version_id (FK → SongVersion)
- bpm
- total_duration
- resolution (ticks / precision)
- source_format (musicxml | midi | manual)
- inserted_at
- updated_at

## Relaciones

- MusicTimeline 1 → N MusicalEvent

---

# 4. MusicalEvent

Unidad mínima de sincronización musical.

## Propósito
Representa notas y eventos en el tiempo.

## Campos

- id
- music_timeline_id (FK → MusicTimeline)
- event_type (note_on | note_off | chord | rest)
- pitch (C4, D4, etc.)
- start_time (float seconds)
- end_time (float seconds)
- duration (float seconds)
- velocity (0–127 opcional)
- voice (melody | left_hand | right_hand)
- color_key (mapping visual)
- index (orden secuencial)
- metadata (jsonb opcional)

---

# 5. PlaybackSession

Representa el estado de reproducción en tiempo real.

## Propósito
Mantener el estado del usuario mientras interactúa con una canción.

## Campos

- id
- song_id
- song_version_id
- current_time (float)
- is_playing (boolean)
- speed (0.5x – 2.0x)
- loop_enabled (boolean)
- started_at
- paused_at
- client_id

## Relaciones

- PlaybackSession N → 1 Song
- PlaybackSession N → 1 SongVersion

---

# 6. ContentAsset

Representa archivos asociados a una canción.

## Propósito
Almacenar recursos multimedia y musicales.

## Campos

- id
- song_id (FK → Song)
- asset_type (musicxml | audio | image | midi)
- file_path
- version
- checksum
- uploaded_by
- inserted_at
- updated_at

---

# 7. User (Futuro)

## Propósito
Representa un usuario del sistema.

## Campos

- id
- email
- password_hash
- name
- role (student | teacher | admin)
- preferences (jsonb)
- inserted_at
- updated_at

---

# 8. UserProgress (Futuro)

## Propósito
Seguimiento del progreso del usuario por canción y nivel.

## Campos

- id
- user_id
- song_id
- song_version_id
- completion_percentage
- accuracy_score
- total_play_time
- last_position_time
- completed (boolean)
- mastery_level (0–5)
- updated_at