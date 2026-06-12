import { OpenSheetMusicDisplay } from "opensheetmusicdisplay"

// Order: C, D, E, F, G, A, B, rest
const NOTE_COLOR_SET = [
  "#FF4444",
  "#FF8C00",
  "#FFD700",
  "#32CD32",
  "#1E90FF",
  "#8A2BE2",
  "#FF69B4",
  "#888888",
]

const OsmdHook = {
  mounted() {
    this.osmd = null
    this.activeNoteEls = []
    this.handleEvent("load_score", ({ musicxml }) => this.loadScore(musicxml))
    this.handleEvent("highlight_note", ({ index, color_key }) => this.highlightNote(index, color_key))
    this.handleEvent("clear_highlight", () => this.clearHighlight())
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

  highlightNote(index, color_key) {
    this.clearHighlight()
    const els = this.el.querySelectorAll(
      `g[data-note-index="${index}"] path, g[data-note-index="${index}"] ellipse`
    )
    els.forEach((el) => {
      el.dataset.origFill = el.style.fill
      el.style.fill = color_key
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
