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

const OsmdHook = {
  mounted() {
    this.osmd = null
    this.activeNoteEls = []
    this.handleEvent("load_score", ({ musicxml }) => this.loadScore(musicxml))
    this.handleEvent("highlight_note", ({ index, color_key }) => this.highlightNote(index, color_key))
    this.handleEvent("clear_highlight", () => this.clearHighlight())
    this.handleEvent("toggle_colors", ({ enabled }) => this.toggleColors(enabled))
  },

  async loadScore(musicxml) {
    if (!this.osmd) {
      this.osmd = new OpenSheetMusicDisplay(this.el, {
        autoResize: true,
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
      this.pushEvent("score_loaded", { total_notes: this.countNotes() })
    } catch (e) {
      console.error("OSMD load error:", e)
    }
  },

  toggleColors(enabled) {
    if (enabled) {
      this.el.classList.remove("colors-disabled")
    } else {
      this.el.classList.add("colors-disabled")
    }
  },

  highlightNote(index, color_key) {
    this.clearHighlight()
    const hex = COLOR_KEY_HEX[color_key] || color_key
    const els = this.el.querySelectorAll(
      `g[data-note-index="${index}"] path, g[data-note-index="${index}"] ellipse`
    )
    els.forEach((el) => {
      el.dataset.origFill = el.style.fill
      el.style.fill = hex
      el.classList.add("note-active")
    })
    this.activeNoteEls = Array.from(els)
  },

  clearHighlight() {
    this.activeNoteEls.forEach((el) => {
      el.style.fill = el.dataset.origFill || ""
      el.classList.remove("note-active")
    })
    this.activeNoteEls = []
  },

  countNotes() {
    if (!this.osmd?.Sheet) return 0
    let count = 0
    this.osmd.Sheet.SourceMeasures.forEach((measure) => {
      measure.VerticalSourceStaffEntryContainers.forEach((container) => {
        container.StaffEntries.forEach((staffEntry) => {
          if (!staffEntry) return
          staffEntry.VoiceEntries.forEach((voiceEntry) => {
            count += voiceEntry.Notes.filter((n) => n.Pitch).length
          })
        })
      })
    })
    return count
  },
}

export default OsmdHook
