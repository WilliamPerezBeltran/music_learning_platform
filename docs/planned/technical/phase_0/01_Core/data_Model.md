# Data Model — Music Learning Platform (Improved MVP + Scalable)

## Core Principle

Este modelo separa claramente:

- Contenido musical (Song)
- Pedagogía (SongVersion)
- Tiempo musical real (MusicTimeline)
- Eventos de sincronización (MusicalEvent)
- Ejecución en tiempo real (PlaybackSession)

---

## 1. Song

Entidad base del sistema.

### Campos

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

### Relaciones

- Song 1 → N SongVersion
- Song 1 → N ContentAsset

---

## 2. SongVersion

Reemplaza SongLevel (más escalable y flexible).

Representa una versión pedagógica o de dificultad.

### Campos

- id
- song_id (FK → Song)
- version_type (melody | simplified | chords | full | custom)
- level_index (orden progresivo)
- name
- description (opcional)
- musicxml_path
- difficulty_score (0–100)
- hand_config (jsonb)
- visibility_config (jsonb)
- is_active (boolean)
- inserted_at
- updated_at

### Relaciones

- SongVersion 1 → 1 MusicTimeline

---

## 3. MusicTimeline

Capa central del sistema de sincronización.

Representa la música ya procesada en tiempo real.

### Campos

- id
- song_version_id (FK → SongVersion)
- bpm
- total_duration
- resolution (ticks / precision)
- source_format (musicxml | midi | manual)
- inserted_at
- updated_at

### Relaciones

- MusicTimeline 1 → N MusicalEvent

---

## 4. MusicalEvent

Unidad mínima de sincronización.

### Campos

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

## 5. PlaybackSession

Estado runtime del sistema.

No es persistente o es parcialmente persistente.

### Campos

- id
- song_id
- song_version_id
- current_time (float)
- is_playing (boolean)
- speed (0.5x – 2.0x)
- loop_enabled (boolean)
- started_at
- paused_at
- client_id (para multi-session futura)

### Relaciones

- PlaybackSession N → 1 Song
- PlaybackSession N → 1 SongVersion

---

## 6. ContentAsset

Sistema centralizado de archivos.

### Campos

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

## 7. User (Futuro)

### Campos

- id
- email
- password_hash
- name
- role (student | teacher | admin)
- preferences (jsonb)
- inserted_at
- updated_at

---

## 8. UserProgress (Futuro)

### Campos

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

---

## Relaciones generales   -> este es mi core -> mvp Basic Core 

# MVP Core

Para validar la idea, el core del MVP sería extremadamente pequeño:

## Core 1: Mostrar una canción

* Cargar una partitura MusicXML.
* Mostrar notas con colores.
* Mostrar nombres (Do, Re, Mi).
* Mostrar letra.

## Core 2: Reproducir la canción

* Botón Play.
* Botón Pause.
* Control de velocidad.
* Resaltar la nota actual mientras suena.

## Core 3: Sistema de niveles

Para una misma canción:

```text
Bartolito
├── Nivel 1 (melodía)
├── Nivel 2 (melodía simplificada)
├── Nivel 3 (acordes básicos)
└── Nivel 4 (completa)
```

## Core 4: Configuración visual

Activar/desactivar:

* Colores
* Nombre de notas
* Acordes
* Mano izquierda
* Mano derecha

## Lo que NO haría en el MVP

* Login social.
* IA.
* Piano2Notes.
* Generación automática de partituras.
* Comunidad.
* Gamificación avanzada.
* Aplicación móvil nativa.
* Seguimiento detallado de progreso.

## Si tuviera que resumir el MVP en una sola frase:

> "Tomar una canción, dividirla en niveles, mostrarla con colores y reproducirla de forma interactiva."

Ese es el núcleo que valida si los niños y principiantes realmente aprenden más rápido con el método de colores. Si eso funciona, todo lo demás se construye encima.




==========================================
==========================================

# MVP Core

## Objetivo

Validar que niños y principiantes pueden aprender canciones más rápido utilizando partituras coloreadas y niveles progresivos.

---

# Core del MVP

## 1. Mostrar una Canción

Permitir visualizar una canción desde una partitura MusicXML.

Características:

* Notas coloreadas.
* Nombre de las notas (Do, Re, Mi, Fa, Sol, La, Si).
* Letra de la canción.
* Diseño responsive para computador, tablet y móvil.

---

## 2. Reproducción Interactiva

Permitir escuchar la canción mientras se sigue visualmente la partitura.

Características:

* Play.
* Pause.
* Stop.
* Control de velocidad.
* Resaltado de la nota actual.

---

## 3. Sistema de Niveles

Cada canción tendrá varias versiones de dificultad.

Ejemplo:

### Bartolito

* Nivel 1: Solo melodía.
* Nivel 2: Melodía simplificada.
* Nivel 3: Melodía + acordes básicos.
* Nivel 4: Mano izquierda simplificada.
* Nivel 5: Canción completa.

Objetivo:

Permitir que el estudiante avance progresivamente hasta interpretar la canción completa.

---

## 4. Configuración Visual

El usuario podrá activar o desactivar:

* Colores.
* Nombre de notas.
* Acordes.
* Mano izquierda.
* Mano derecha.
* Letra.

---

# Contenido Inicial

Lanzar con un conjunto reducido de canciones.

Ejemplos:

* Bartolito.
* Estrellita.
* Feliz Cumpleaños.
* Los Pollitos.
* Himno de la Alegría.

Cada una con múltiples niveles.

---

# Fuera del MVP

No desarrollar inicialmente:

* Inteligencia Artificial.
* Piano2Notes.
* Generación automática de partituras.
* Aplicaciones móviles nativas.
* Comunidad.
* Sistema de logros.
* Gamificación avanzada.
* Marketplace de canciones.

---

# Métrica Principal

Validar que un usuario pueda:

1. Elegir una canción.
2. Seleccionar un nivel.
3. Seguir la partitura coloreada.
4. Reproducir la canción.
5. Aprender la melodía más rápido que con una partitura tradicional.

Si esta hipótesis se valida, se podrá construir el resto de la plataforma sobre esta base.