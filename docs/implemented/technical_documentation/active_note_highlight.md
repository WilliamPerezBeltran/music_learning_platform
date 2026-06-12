# Resaltado de Nota Activa

## Archivos modificados

- `assets/js/osmd_hook.js`
- `test/music_learning_platform/application/sync/note_tracker_test.exs`
- `test/music_learning_platform_web/live/song_live_test.exs`

---

## Descripción

Cuando el usuario está en modo blanco y negro y presiona play, la nota que está sonando se ilumina con el color de su altura musical. El resto de las notas permanecen en negro. Al pasar a la siguiente nota, la anterior vuelve a negro y la nueva se ilumina.

---

## Causa raíz del problema

Los logs del navegador mostraban que el estilo se aplicaba correctamente al elemento SVG (`fill: rgb(255, 215, 0) !important`), pero visualmente no ocurría ningún cambio.

**Problema 1 — referencias DOM obsoletas:**

OSMD tenía `autoResize: true`. Al cargar la canción, LiveView aplica un diff de DOM que hace aparecer los controles de reproducción, reduciendo la altura del contenedor del pentagrama. OSMD detecta el cambio de tamaño, vuelve a renderizar el SVG y crea elementos nuevos con IDs distintos. `buildNoteElementMap()` ya había guardado referencias a los nodos anteriores, que quedan desconectados del DOM. Al llamar `highlightNote()`, los estilos se aplican sobre nodos invisibles.

**Problema 2 — formato de `color_key`:**

La base de datos fue sembrada con el formato hex antiguo (`"#FF4444"`, `"#1E90FF"`, etc.). `COLOR_KEY_HEX["#FF4444"]` devuelve `undefined`, cayendo al fallback amarillo `#FFD700`, que es invisible sobre fondo blanco.

---

## Solución

### `autoResize: false`

Desactiva el re-renderizado automático de OSMD. Los elementos SVG permanecen en el DOM y las referencias almacenadas siguen siendo válidas.

### `graphicalNotes[]` — objetos OSMD en lugar de nodos DOM

Se almacenan objetos `GraphicalNote` de OSMD en vez de referencias directas a elementos SVG. En `highlightNote`, se obtiene el nodo vivo mediante `getSVGGElement()` (que usa `document.getElementById` internamente). Si el nodo no está conectado al DOM, se reconstruye el mapa y se reintenta.

```js
let groupEl = gNote.getSVGGElement?.()
if (!groupEl || !groupEl.isConnected) {
  this.buildNoteElementMap()
  groupEl = this.graphicalNotes[index]?.getSVGGElement?.()
  if (!groupEl || !groupEl.isConnected) return
}
```

### `resolveHex()` — soporte de formatos mixtos

Acepta tanto claves semánticas (`"do"`) como hex directos (`"#FF4444"`):

```js
function resolveHex(colorKey) {
  if (!colorKey) return "#E53935"
  if (colorKey.startsWith("#")) return colorKey
  return COLOR_KEY_HEX[colorKey] || "#E53935"
}
```

### Fill + drop-shadow

En modo blanco y negro, se aplican dos efectos sobre el grupo SVG de la nota activa:

- `fill` y `stroke` con el color de la altura musical en todos los `path` y `ellipse` internos
- `filter: drop-shadow` doble sobre el elemento grupo para hacer visible el halo incluso en notas de color claro (como `mi` en amarillo sobre fondo blanco)

```js
targets.forEach(t => {
  t.style.setProperty("fill", hex, "important")
  t.style.setProperty("stroke", hex, "important")
})
groupEl.style.setProperty(
  "filter",
  `drop-shadow(0 0 5px ${hex}) drop-shadow(0 0 2px ${hex})`,
  "important"
)
```

`clearHighlight()` restaura los estilos originales al pasar a la siguiente nota.

---

## Flujo

```
Tone.js Transport
  → Tone.getDraw().schedule → callback al frame de audio
    → pushEvent("note_active", { index, color_key, current_time })
      → LiveView handle_event("note_active")
        → NoteTracker.set_active / StateModel.set_position
        → push_event(socket, "highlight_note", %{index, color_key})
          → OsmdHook handleEvent("highlight_note")
            → resolveHex(color_key) → hex
            → gNote.getSVGGElement() → nodo vivo del DOM
            → setProperty fill + stroke + filter
```

---

## Tests agregados

**`note_tracker_test.exs`**

- `set_active` almacena el índice activo
- `get_active` lo recupera correctamente
- Sobrescritura del índice activo previo
- Error al consultar sesión sin nota activa
- Aislamiento entre sesiones distintas
- `reset` limpia la sesión
- `seek` limpia la nota activa

**`song_live_test.exs`**

- `note_active` con `color_key` semántico (`"do"`)
- `note_active` con `color_key` en formato hex legado (`"#FF4444"`)
- `note_active` con índice cero
- `note_active` con índice grande (999)
- `note_active` con los cuatro formatos hex del seed antiguo

---

## Decisiones de diseño

- **`autoResize: false`**: trade-off aceptado en Fase 0. El pentagrama no se redimensiona al cambiar el tamaño de ventana. Se puede retomar en una fase posterior con un handler de `window.resize` que llame a `osmd.render()` y reconstruya `graphicalNotes[]`.
- **`resolveHex` en el frontend**: la normalización del formato de `color_key` se hace en JS para no requerir migración de datos en esta fase.
- **Drop-shadow doble**: necesario para que colores claros (mi/amarillo) sean perceptibles sobre fondo blanco.
