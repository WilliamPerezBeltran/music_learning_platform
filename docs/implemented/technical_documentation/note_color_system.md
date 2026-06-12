# Sistema de Colores por Nota

## Ubicación

`assets/js/osmd_hook.js`

## Descripción

Las notas de la partitura se colorean automáticamente según su pitch al momento del render. El sistema usa la API nativa de OSMD (`coloringMode: CustomColorSet`) para aplicar un conjunto de 8 colores durante la generación del SVG, sin necesidad de manipulación manual del DOM ni iteración post-render.

## Mapa de colores

| Nota | Color     | Hex       |
|------|-----------|-----------|
| C    | Rojo      | `#FF4444` |
| D    | Naranja   | `#FF8C00` |
| E    | Amarillo  | `#FFD700` |
| F    | Verde     | `#32CD32` |
| G    | Azul      | `#1E90FF` |
| A    | Morado    | `#8A2BE2` |
| B    | Rosa      | `#FF69B4` |
| Silencio | Gris | `#888888` |

## Implementación

### Opciones del constructor OSMD

```js
this.osmd = new OpenSheetMusicDisplay(this.el, {
  coloringEnabled: true,
  coloringMode: 2,          // ColoringModes.CustomColorSet
  coloringSetCustom: NOTE_COLOR_SET,
})
```

- `coloringEnabled: true` — habilita el sistema de colores
- `coloringMode: 2` — activa el modo `CustomColorSet` (C→B + silencio)
- `coloringSetCustom` — array de 8 colores en orden C, D, E, F, G, A, B, silencio

OSMD aplica los colores internamente durante `osmd.render()`.

## Decisión de diseño

El enfoque anterior intentaba iterar `GraphicSheet.MeasureList` después del render y setear `gNote.noteHead.style`, lo cual no funciona porque `noteHead` es un objeto interno de OSMD, no un elemento DOM.

La alternativa de setear `note.NoteheadColor` en `Sheet.SourceMeasures` antes del render también falló porque requería `coloringEnabled: true` y aun así es menos confiable que el modo nativo `CustomColorSet`.

El modo `CustomColorSet` es la API oficial de OSMD para este caso de uso y no requiere lógica adicional.

## Limitación actual

El highlight de la nota activa durante la reproducción no está implementado. El flujo de señales existe (Tone.js → `note_active` → LiveView → `highlight_note` → OsmdHook) pero el selector `g[data-note-index]` no encuentra elementos porque OSMD no genera esos atributos en el SVG.
