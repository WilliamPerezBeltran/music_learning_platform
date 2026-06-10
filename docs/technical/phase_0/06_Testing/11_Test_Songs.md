# 11 — Canciones de Prueba

## Rol
Define las canciones usadas para validar el stack técnico durante la Fase 0.

Cada canción cumple un propósito específico de validación.
No son contenido final del producto — son herramientas de prueba.

---

## Canciones

### Bartolito ← demo principal de Fase 0
Canción infantil latinoamericana. Melodía simple, notas cortas, ritmo claro.

Valida:
- Renderizado completo de partitura en OSMD
- Reproducción de audio con Tone.js
- Sincronización partitura ↔ audio
- Sistema de colores por nota
- Controles play / pause / stop
- Control de velocidad

Niveles requeridos para Fase 0:
- `level1.xml` — solo melodía

### Estrellita
Melodía corta y conocida. Útil para probar cambio entre canciones.

Valida:
- Carga de MusicXML desde `priv/static/`
- Cambio de canción sin recargar la página
- Reset del estado de reproducción al cambiar canción

Niveles requeridos para Fase 0:
- `level1.xml` — melodía completa

### Feliz Cumpleaños
Canción con notas repetidas y saltos de octava. Útil para probar edge cases del parser.

Valida:
- Parseo correcto de notas con diferentes octavas
- Asignación de color_key independiente de octava
- Duración variable de notas

Niveles requeridos para Fase 0:
- `level1.xml` — melodía completa

---

## Formatos Requeridos por Canción

| Formato | Fase 0 | Futuro |
|---|---|---|
| MusicXML (.xml) | Obligatorio | Obligatorio |
| MIDI (.mid) | No requerido | Opcional |
| PDF (.pdf) | No requerido | Opcional |

Solo se necesitan archivos MusicXML para completar Fase 0.

---

## Ubicación en el Proyecto

```
priv/
└── static/
    └── songs/
        ├── bartolito/
        │   └── level1.xml
        ├── estrellita/
        │   └── level1.xml
        └── feliz_cumpleanos/
            └── level1.xml
```

---

## Criterios de Validación por Paso

| Paso | Canción | Qué se valida |
|---|---|---|
| 0.2 | Bartolito | OSMD renderiza el MusicXML sin errores |
| 0.3 | Estrellita | Cambio de canción recarga OSMD correctamente |
| 0.4 | Bartolito | Tone.js reproduce las notas en orden |
| 0.5 | Bartolito | Nota visual y nota sonora coinciden en el tiempo |
| 0.6 | Bartolito | El highlight se mueve nota a nota durante la reproducción |
| 0.7 | Bartolito | Play / Pause / Stop funcionan sin desincronización |
| 0.8 | Bartolito | Velocidad 0.5x y 2.0x mantienen la sincronización |
| 0.9 | Feliz Cumpleaños | Todas las notas tienen el color correcto según su pitch |
| 0.10 | Bartolito | Demo completa: colores + audio + highlight + controles |

---

## Hitos Fase 0

| Paso | Tarea |
|---|---|
| 0.10 | Demo funcional completa con Bartolito |
