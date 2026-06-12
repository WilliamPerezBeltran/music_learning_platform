import * as Tone from "tone"

const TonePlayerHook = {
  mounted() {
    this.synth = null
    this.part = null
    this.notes = []

    this.handleEvent("tone_play", (payload) => this.play(payload))
    this.handleEvent("tone_pause", (payload) => this.pause(payload))
    this.handleEvent("tone_stop", () => this.stop())
    this.handleEvent("tone_set_tempo", (payload) => this.setTempo(payload))
  },

  destroyed() {
    this.cleanup()
  },

  initSynth() {
    if (!this.synth) {
      this.synth = new Tone.PolySynth(Tone.Synth, {
        maxPolyphony: 16,
        oscillator: { type: "triangle" },
        envelope: { attack: 0.02, decay: 0.1, sustain: 0.5, release: 0.4 },
      }).toDestination()
    }
  },

  async play({ bpm, speed, current_time, events }) {
    await Tone.start()

    this.initSynth()
    this.cleanup()

    this.notes = events

    // Schedule notes scaled by speed factor
    // start_times are in seconds at base BPM (1x speed)
    const scheduled = events.map((e) => ({
      time: e.start_time / speed,
      pitch: e.pitch,
      duration: Math.max(e.duration / speed - 0.02, 0.05),
      index: e.index,
      color_key: e.color_key,
    }))

    this.part = new Tone.Part((time, note) => {
      this.synth.triggerAttackRelease(note.pitch, note.duration, time)
      Tone.getDraw().schedule(() => {
        this.pushEvent("tone_note_on", { index: note.index, color_key: note.color_key })
      }, time)
    }, scheduled)

    this.part.start(0)

    const offset = current_time / speed
    Tone.getTransport().start("+0.1", offset)
  },

  pause({ current_time }) {
    Tone.getTransport().pause()
  },

  stop() {
    const transport = Tone.getTransport()
    transport.stop()
    transport.position = 0
    if (this.part) {
      this.part.dispose()
      this.part = null
    }
    this.pushEvent("tone_stopped", {})
  },

  setTempo({ bpm, speed, current_time, events }) {
    if (events && events.length > 0) {
      this.play({ bpm, speed, current_time, events })
    }
  },

  cleanup() {
    if (this.part) {
      this.part.dispose()
      this.part = null
    }
    Tone.getTransport().stop()
    Tone.getTransport().position = 0
  },
}

export default TonePlayerHook
