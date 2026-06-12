import * as Tone from "tone"

const TonePlayerHook = {
  mounted() {
    this.synth = null
    this.rawEvents = []
    this.baseBpm = 120
    this.currentSpeed = 1.0
    this.baseTimeAtPause = 0.0

    this.handleEvent("load_events", (payload) => this.loadEvents(payload))
    this.handleEvent("play", (payload) => this.play(payload))
    this.handleEvent("pause", () => this.pause())
    this.handleEvent("stop", () => this.stop())
    this.handleEvent("set_speed", (payload) => this.setSpeed(payload))
  },

  destroyed() {
    this.cleanup()
  },

  // --- Event handlers ---

  loadEvents({ events, base_bpm }) {
    this.rawEvents = events
    this.baseBpm = base_bpm
    this._schedule(this.currentSpeed)
  },

  async play({ current_time, bpm }) {
    await Tone.start()
    this._initSynth()

    const speed = bpm / this.baseBpm
    this.currentSpeed = speed

    const transport = Tone.getTransport()
    transport.bpm.value = bpm

    // Cancel previously scheduled events and reschedule at current speed
    this._schedule(speed)

    // Convert base time to transport time: transport runs `speed` times faster
    const offset = current_time / speed
    transport.start("+0.1", offset)
  },

  pause() {
    const transport = Tone.getTransport()
    // Record base time so resume can seek back to the right position
    this.baseTimeAtPause = transport.seconds * this.currentSpeed
    transport.pause()
  },

  stop() {
    const transport = Tone.getTransport()
    transport.stop()
    transport.cancel()
    this.baseTimeAtPause = 0.0
  },

  setSpeed({ bpm }) {
    const newSpeed = bpm / this.baseBpm
    const transport = Tone.getTransport()
    const wasPlaying = transport.state === "started"

    // Capture current base position before stopping
    const baseTime = wasPlaying
      ? transport.seconds * this.currentSpeed
      : this.baseTimeAtPause

    this.currentSpeed = newSpeed
    transport.bpm.value = bpm

    // Reschedule events with new speed scaling
    this._schedule(newSpeed)

    if (wasPlaying) {
      transport.start("+0.1", baseTime / newSpeed)
    }
  },

  // --- Private ---

  _initSynth() {
    if (!this.synth) {
      this.synth = new Tone.Synth({
        oscillator: { type: "triangle" },
        envelope: { attack: 0.02, decay: 0.1, sustain: 0.5, release: 0.4 },
      }).toDestination()
    }
  },

  _schedule(speed) {
    Tone.getTransport().cancel()

    this.rawEvents.forEach((event) => {
      const transportTime = event.start_time / speed
      const transportDuration = Math.max(event.duration / speed - 0.02, 0.05)

      Tone.getTransport().schedule((time) => {
        this.synth.triggerAttackRelease(event.pitch, transportDuration, time)
        Tone.getDraw().schedule(() => {
          this.pushEvent("note_active", { index: event.index, color_key: event.color_key, current_time: event.start_time })
        }, time)
      }, transportTime)
    })
  },

  cleanup() {
    const transport = Tone.getTransport()
    transport.stop()
    transport.cancel()
    if (this.synth) {
      this.synth.dispose()
      this.synth = null
    }
  },
}

export default TonePlayerHook
