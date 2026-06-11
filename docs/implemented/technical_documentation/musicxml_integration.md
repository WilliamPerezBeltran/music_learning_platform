# Integración MusicXML — Pipeline de Procesamiento

## ¿Qué hace el sistema?

Convierte archivos MusicXML almacenados en `priv/static/songs/` en eventos musicales con tiempo exacto persistidos en la base de datos.
El resultado es una lista de `MusicalEvent` que el Sync Engine usa para sincronizar audio y visual durante la reproducción.

---

## ¿Cómo está construido?

### Archivos MusicXML

```
priv/static/songs/
├── bartolito_level1.xml       ← Bartolito, solo melodía, 4/4, 120 BPM, 12 compases
└── estrellita_level1.xml      ← Estrellita, solo melodía, 3/4, 100 BPM, 18 compases
```

Convención de nombres: `{slug_canción}_level{n}.xml`

### Archivos del pipeline

```
lib/music_learning_platform/infrastructure/
├── storage/
│   └── file_storage.ex            ← lee archivos de priv/static/songs/
└── musicxml/
    ├── musicxml_parser.ex         ← XML → lista de notas con tiempo
    └── timeline_builder.ex        ← persiste MusicTimeline + MusicalEvents en DB

lib/music_learning_platform/infrastructure/workers/
└── musicxml_worker.ex             ← orquesta el pipeline completo
```

### Seeds

```
priv/repo/seeds.exs                ← crea canciones, versiones y ejecuta el pipeline
```

---

## ¿Cómo funciona internamente?

### Pipeline completo

```
priv/static/songs/{archivo}.xml
        ↓
FileStorage.read(path)             ← lee el XML del disco
        ↓
MusicXMLParser.parse(xml_string)   ← extrae notas con tiempo
        ↓
TimelineBuilder.build_from_parsed  ← persiste en DB (transacción)
        ↓
MusicTimeline                      ← bpm, total_duration, resolution
MusicalEvent[]                     ← lista de notas listas para el Sync Engine
```

### Parser (measure por measure)

El parser procesa el XML medida a medida para mantener `divisions` actualizado por sección:

```
Para cada <measure>:
  1. Leer <divisions> si cambia
  2. Para cada <note>:
     - Si tiene <rest> → avanzar tiempo, no crear evento
     - Si tiene <chord> → mismo start_time que la nota anterior
     - Si es nota normal → crear evento y avanzar tiempo
  3. duration_seconds = duration / divisions * (60.0 / bpm)
```

Campos extraídos de cada `<note>`:

| Campo | Fuente MusicXML | Ejemplo |
|---|---|---|
| `pitch` | `<step>` + `<octave>` | `C4`, `G4` |
| `start_time` | offset acumulado | `0.5` (segundos) |
| `end_time` | `start_time + duration` | `1.0` |
| `duration` | `<duration>` / `<divisions>` × 60/bpm | `0.5` |
| `voice` | `<voice>` → 1=right_hand, 2=left_hand | `right_hand` |
| `color_key` | `ColorMapper.color_for_pitch(pitch)` | `#FF4444` |
| `index` | posición secuencial | `0, 1, 2...` |

### Seeds

Los seeds son idempotentes: usan `Repo.get_by` antes de insertar.
Si una canción o versión ya existe, la reutilizan sin duplicar.

```
Para cada canción:
  1. Song.get_by(title) o insert
  2. ContentAsset.get_by(song_id, asset_type) o insert
  3. SongVersion.get_by(song_id, version_type) o insert
  4. MusicXMLWorker.process(version_id, musicxml_path)
     → crea MusicTimeline + inserta todos los MusicalEvents en bulk
```

### Resultado en DB tras ejecutar seeds

| Tabla | Registros |
|---|---|
| `songs` | 2 (Bartolito, Estrellita) |
| `song_versions` | 2 (una versión "melody" por canción) |
| `content_assets` | 2 (un asset musicxml por canción) |
| `music_timelines` | 2 (uno por versión) |
| `musical_events` | 42 × 2 = 84 eventos |

---

## ¿Cómo se modifica sin romperlo?

### Agregar una nueva canción

1. Crear el archivo `.xml` en `priv/static/songs/` con la convención `{slug}_level{n}.xml`
2. Agregar la entrada en `priv/repo/seeds.exs`
3. Ejecutar `mix run priv/repo/seeds.exs`

### Agregar un nuevo nivel a una canción existente

1. Crear el archivo XML del nivel
2. Agregar la versión en `priv/repo/seeds.exs` bajo la canción correspondiente
3. Ejecutar `mix run priv/repo/seeds.exs`

### Re-procesar una canción desde cero

```bash
# Borrar timeline y eventos de la versión en DB
# Luego volver a correr seeds
mix run priv/repo/seeds.exs
```

### Ejecutar seeds en Docker

```bash
docker compose exec app mix run priv/repo/seeds.exs
```
