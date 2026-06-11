# Music Learning Platform — Database Diagram (ERD)

---

# DIAGRAMA GENERAL

```txt
+------------------+
|      songs       |
+------------------+
| id (PK)          |
| title            |
| artist           |
| category         |
| duration         |
| metadata         |
+------------------+
        |
        | 1 → N
        v
+------------------------+
|    song_versions       |
+------------------------+
| id (PK)                |
| song_id (FK)           |
| version_type           |
| level_index            |
| musicxml_path         |
| difficulty_score       |
+------------------------+
        |
        | 1 → 1
        v
+------------------------+
|   music_timelines      |
+------------------------+
| id (PK)                |
| song_version_id (FK)   |
| bpm                    |
| total_duration        |
| resolution            |
+------------------------+
        |
        | 1 → N
        v
+------------------------+
|    musical_events      |
+------------------------+
| id (PK)                |
| music_timeline_id (FK) |
| event_type            |
| pitch                 |
| start_time           |
| end_time             |
+------------------------+

----------------------------------------------------

+------------------------+
|   playback_sessions    |
+------------------------+
| id (PK)                |
| song_id (FK)           |
| song_version_id (FK)   |
| current_time          |
| is_playing            |
| speed                 |
+------------------------+

----------------------------------------------------

+------------------------+
|     content_assets     |
+------------------------+
| id (PK)                |
| song_id (FK)           |
| asset_type            |
| file_path            |
+------------------------+

----------------------------------------------------

(FUTURO)

+------------------------+
|        users           |
+------------------------+
| id (PK)                |
| email                 |
| role                  |
+------------------------+
        |
        | 1 → N
        v
+------------------------+
|    user_progress       |
+------------------------+
| id (PK)                |
| user_id (FK)          |
| song_id (FK)          |
| song_version_id (FK)  |
| completion %          |
+------------------------+