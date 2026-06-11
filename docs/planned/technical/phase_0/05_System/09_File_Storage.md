# 09 — Almacenamiento de Archivos

## Rol
Define dónde viven los archivos musicales (MusicXML, audio, imágenes)
y cómo los carga el sistema en Fase 0.

---

## Decisión Fase 0

Ubicación: `priv/static/songs/`

Razón: solución más simple para validación técnica.
No requiere configuración de infraestructura externa.
Los archivos se sirven directamente por Phoenix.

---

## Estructura de Directorios

```
priv/
└── static/
    └── songs/
        ├── bartolito/
        │   ├── level1.xml
        │   ├── level2.xml
        │   └── level3.xml
        ├── estrellita/
        │   └── level1.xml
        └── feliz_cumpleanos/
            └── level1.xml
```

Convención: `priv/static/songs/{song_slug}/level{n}.xml`

---

## Módulo de Carga

### `song_loader.ex`
Lee los archivos MusicXML desde `priv/static/songs/`.
Asocia cada archivo a su `SongVersion` correspondiente.
Retorna el contenido XML como string para el pipeline de procesamiento.

```
song_loader.ex
  load(song_slug, level_index) → {:ok, xml_string} | {:error, reason}
```

---

## Entidad ContentAsset

Cada archivo asociado a una canción se registra como un `ContentAsset`:

```
asset_type   — musicxml | audio | image | midi
file_path    — ruta relativa desde priv/static/
version      — versión del archivo
checksum     — hash para detectar cambios
```

En Fase 0 solo se usan archivos `musicxml`.
Los tipos `audio` e `image` se incorporan en fases posteriores.

---

## Camino a Producción

| Etapa | Almacenamiento |
|---|---|
| Fase 0 | `priv/static/songs/` — archivos locales |
| Fase 1+ | S3 / Cloudflare R2 — almacenamiento externo |

La migración a S3/R2 solo requiere cambiar `song_loader.ex` —
el resto del pipeline no cambia porque recibe siempre el XML como string.

---

## Restricción

Los archivos MusicXML no se leen dentro de un LiveView `mount` o `handle_event`.
`song_loader.ex` es llamado exclusivamente desde `musicxml_worker.ex` (async).

---

## Hitos Fase 0

| Paso | Tarea |
|---|---|
| 0.3 | Cargar MusicXML desde `priv/static/`, cambiar entre canciones |
