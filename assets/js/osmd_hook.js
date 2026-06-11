import { OpenSheetMusicDisplay } from "opensheetmusicdisplay"

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
      })
    }
    await this.osmd.load(musicxml)
    this.osmd.render()
    this.applyNoteColors()
    this.pushEvent("score_loaded", { total_notes: this.countNotes() })
  },

  applyNoteColors() {
    if (!this.osmd || !this.osmd.GraphicSheet) return

    const noteColorMap = {
      "C": "#FF4444", "D": "#FF8C00", "E": "#FFD700",
      "F": "#32CD32", "G": "#1E90FF", "A": "#8A2BE2", "B": "#FF69B4",
    }

    this.osmd.GraphicSheet.MeasureList.forEach(measures => {
      measures.forEach(measure => {
        if (!measure) return
        measure.staffEntries.forEach(entry => {
          entry.graphicalVoiceEntries.forEach(voiceEntry => {
            voiceEntry.notes.forEach(gNote => {
              const step = gNote.sourceNote?.pitch?.step
              if (!step) return
              const color = noteColorMap[step] || "#333333"
              if (gNote.noteHead) {
                gNote.noteHead.style = `fill: ${color}`
              }
            })
          })
        })
      })
    })
  },

  highlightNote(index, color_key) {
    this.clearHighlight()
    const els = this.el.querySelectorAll(
      `g[data-note-index="${index}"] path, g[data-note-index="${index}"] ellipse`
    )
    els.forEach(el => {
      el.dataset.origFill = el.style.fill
      el.style.fill = color_key
      el.classList.add("note-active")
    })
    this.activeNoteEls = Array.from(els)
  },

  clearHighlight() {
    this.activeNoteEls.forEach(el => {
      el.style.fill = el.dataset.origFill || ""
      el.classList.remove("note-active")
    })
    this.activeNoteEls = []
  },

  countNotes() {
    if (!this.osmd || !this.osmd.GraphicSheet) return 0
    let count = 0
    this.osmd.GraphicSheet.MeasureList.forEach(measures => {
      measures.forEach(measure => {
        if (!measure) return
        measure.staffEntries.forEach(entry => {
          entry.graphicalVoiceEntries.forEach(ve => { count += ve.notes.length })
        })
      })
    })
    return count
  },
}

export default OsmdHook
