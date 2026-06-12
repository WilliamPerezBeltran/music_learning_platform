import { OpenSheetMusicDisplay } from "opensheetmusicdisplay"

// Order: C(do), D(re), E(mi), F(fa), G(sol), A(la), B(si), rest
const NOTE_COLOR_SET = [
  "#E53935",
  "#FB8C00",
  "#FDD835",
  "#43A047",
  "#1E88E5",
  "#8E24AA",
  "#E91E63",
  "#888888",
]

const COLOR_KEY_HEX = {
  do:  "#E53935",
  re:  "#FB8C00",
  mi:  "#FDD835",
  fa:  "#43A047",
  sol: "#1E88E5",
  la:  "#8E24AA",
  si:  "#E91E63",
}

// Accepts both semantic keys ("do") and raw hex values ("#FF4444")
function resolveHex(colorKey) {
  if (!colorKey) return "#E53935"
  if (colorKey.startsWith("#")) return colorKey
  return COLOR_KEY_HEX[colorKey] || "#E53935"
}

const OsmdHook = {
  mounted() {
    this.osmd = null
    this.graphicalNotes = []  // GraphicalNote objects — stable across OSMD re-renders
    this.activeGroupEl = null
    this.activeTargets = []
    this.handleEvent("load_score", ({ musicxml }) => this.loadScore(musicxml))
    this.handleEvent("highlight_note", ({ index, color_key }) => this.highlightNote(index, color_key))
    this.handleEvent("clear_highlight", () => this.clearHighlight())
    this.handleEvent("toggle_colors", ({ enabled }) => this.toggleColors(enabled))
  },

  async loadScore(musicxml) {
    if (!this.osmd) {
      this.osmd = new OpenSheetMusicDisplay(this.el, {
        autoResize: false,
        drawTitle: true,
        drawSubtitle: false,
        drawComposer: false,
        coloringEnabled: true,
        coloringMode: 2,
        coloringSetCustom: NOTE_COLOR_SET,
      })
    }

    try {
      await this.osmd.load(musicxml)
      this.osmd.render()
      this.buildNoteElementMap()
      this.pushEvent("score_loaded", { total_notes: this.graphicalNotes.length })
    } catch (e) {
      console.error("OSMD load error:", e)
    }
  },

  buildNoteElementMap() {
    this.graphicalNotes = []
    const staffLists = this.osmd?.GraphicSheet?.MeasureList
    if (!staffLists?.length) return

    const measureCount = staffLists[0]?.length || 0
    for (let m = 0; m < measureCount; m++) {
      for (let s = 0; s < staffLists.length; s++) {
        const measure = staffLists[s]?.[m]
        if (!measure) continue
        measure.staffEntries.forEach((entry) => {
          entry.graphicalVoiceEntries.forEach((voiceEntry) => {
            voiceEntry.notes.forEach((gNote) => {
              if (!gNote.sourceNote?.Pitch) return
              this.graphicalNotes.push(gNote)
            })
          })
        })
      }
    }
  },

  highlightNote(index, color_key) {
    this.clearHighlight()
    const gNote = this.graphicalNotes[index]
    if (!gNote) return

    // getSVGGElement() queries document.getElementById() — always returns live DOM node
    let groupEl = gNote.getSVGGElement?.()

    // If re-render happened and IDs changed, rebuild map and retry
    if (!groupEl || !groupEl.isConnected) {
      this.buildNoteElementMap()
      groupEl = this.graphicalNotes[index]?.getSVGGElement?.()
      if (!groupEl || !groupEl.isConnected) return
    }

    const bwMode = this.el.classList.contains("colors-disabled")
    const hex = resolveHex(color_key)

    const targets = groupEl.querySelectorAll("path, ellipse")
    targets.forEach((t) => {
      t.dataset.origStyle = t.getAttribute("style") || ""
      if (bwMode) {
        // Override the CSS fill: black !important with inline fill: color !important
        t.style.setProperty("fill", hex, "important")
        t.style.setProperty("stroke", hex, "important")
      }
    })

    // Glow on the group for visibility regardless of mode
    groupEl.dataset.origGroupStyle = groupEl.getAttribute("style") || ""
    groupEl.style.setProperty("filter", `drop-shadow(0 0 5px ${hex}) drop-shadow(0 0 2px ${hex})`, "important")

    this.activeGroupEl = groupEl
    this.activeTargets = Array.from(targets)
  },

  clearHighlight() {
    this.activeTargets.forEach((t) => {
      t.style.removeProperty("fill")
      t.style.removeProperty("stroke")
      const orig = t.dataset.origStyle
      if (orig) t.setAttribute("style", orig)
      else t.removeAttribute("style")
    })

    if (this.activeGroupEl) {
      this.activeGroupEl.style.removeProperty("filter")
      const orig = this.activeGroupEl.dataset.origGroupStyle
      if (orig) this.activeGroupEl.setAttribute("style", orig)
      else this.activeGroupEl.removeAttribute("style")
      this.activeGroupEl = null
    }

    this.activeTargets = []
  },

  toggleColors(enabled) {
    if (enabled) {
      this.el.classList.remove("colors-disabled")
    } else {
      this.el.classList.add("colors-disabled")
    }
  },
}

export default OsmdHook
