# 07 — Sistema de Mapeo de Colores

## Rol
El sistema de colores asigna un color único a cada nota musical.
Permite que niños y principiantes identifiquen las notas visualmente sin leer notación tradicional.

Los colores se aplican en la partitura SVG (OSMD) y en el highlight durante la reproducción.

---

## Tabla de Mapeo

| Nota | color_key | Color | Hex |
|---|---|---|---|
| Do (C) | `do` | Rojo | `#E53935` |
| Re (D) | `re` | Naranja | `#FB8C00` |
| Mi (E) | `mi` | Amarillo | `#FDD835` |
| Fa (F) | `fa` | Verde | `#43A047` |
| Sol (G) | `sol` | Azul | `#1E88E5` |
| La (A) | `la` | Violeta | `#8E24AA` |
| Si (B) | `si` | Rosa | `#E91E63` |

El color_key se deriva del nombre de nota (paso de pitch) — independiente de la octava.
Do3, Do4 y Do5 tienen el mismo color_key `do`.

---

## Módulo Backend

### `color_mapper.ex`
Define el mapeo completo pitch → color_key.
Expone una función que recibe el pitch de un MusicalEvent y retorna su color_key.

```
color_mapper.ex
  get_color_key(pitch) → color_key
```

El color_key se almacena directamente en cada `MusicalEvent` al construir el timeline.

---

## Aplicación en OSMD

Los colores se aplican como clases CSS sobre los elementos SVG de las notas.
`osmd_hook.js` aplica las clases al renderizar la partitura en `load_score`.

```css
.note-do  { fill: #E53935; }
.note-re  { fill: #FB8C00; }
.note-mi  { fill: #FDD835; }
.note-fa  { fill: #43A047; }
.note-sol { fill: #1E88E5; }
.note-la  { fill: #8E24AA; }
.note-si  { fill: #E91E63; }
```

El estado de highlight activo es una clase CSS adicional superpuesta — no reemplaza el color base.

---

## Configuración Visual

El usuario puede activar o desactivar los colores desde la interfaz.
Esto se gestiona en `notation_config.ex` (capa visual del backend).

Cuando los colores están desactivados:
- Las clases CSS de color no se aplican al SVG
- Las notas se renderizan en negro (notación tradicional)

El toggle no requiere recargar la partitura — se actualiza vía LiveView.

---

## Flujo Completo

```
MusicXML → musicxml_parser.ex extrae pitch
    ↓
color_mapper.ex asigna color_key al MusicalEvent
    ↓
MusicalEvent almacenado con color_key
    ↓
LiveView envía load_score con eventos a osmd_hook.js
    ↓
osmd_hook.js aplica clase CSS .note-{color_key} a cada nota SVG
```

---

## Hitos Fase 0

| Paso | Tarea |
|---|---|
| 0.9 | Sistema de colores por nota aplicado en la partitura |
