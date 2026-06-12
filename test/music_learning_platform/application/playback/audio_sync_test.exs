defmodule MusicLearningPlatform.Application.Playback.AudioSyncTest do
  use ExUnit.Case, async: true

  alias MusicLearningPlatform.Application.Playback.AudioSync
  alias MusicLearningPlatform.State.StateModel

  defp state(opts) do
    %StateModel{
      session_id: "test",
      song_id: 1,
      song_version_id: 1,
      current_time: Keyword.get(opts, :current_time, 0.0),
      is_playing: Keyword.get(opts, :is_playing, false),
      speed: Keyword.get(opts, :speed, 1.0),
      events: Keyword.get(opts, :events, [])
    }
  end

  defp note_event(attrs \\ %{}) do
    Map.merge(
      %{
        event_type: "note_on",
        pitch: "C4",
        start_time: 0.5,
        duration: 0.5,
        index: 0,
        color_key: "#FF4444"
      },
      attrs
    )
  end

  describe "build_play_payload/2" do
    test "returns bpm equal to base_bpm when speed is 1.0" do
      payload = AudioSync.build_play_payload(state(speed: 1.0), 120.0)
      assert payload.bpm == 120.0
    end

    test "scales bpm by speed factor" do
      assert AudioSync.build_play_payload(state(speed: 0.5), 120.0).bpm == 60.0
      assert AudioSync.build_play_payload(state(speed: 2.0), 120.0).bpm == 240.0
      assert AudioSync.build_play_payload(state(speed: 0.75), 120.0).bpm == 90.0
    end

    test "includes speed and current_time" do
      payload = AudioSync.build_play_payload(state(speed: 1.5, current_time: 3.0), 100.0)
      assert payload.speed == 1.5
      assert payload.current_time == 3.0
    end

    test "serializes note_on events with pitch" do
      events = [note_event(%{pitch: "G4", index: 2, color_key: "#1E90FF"})]
      payload = AudioSync.build_play_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
      [e] = payload.events
      assert e.pitch == "G4"
      assert e.index == 2
      assert e.color_key == "#1E90FF"
    end

    test "excludes events with nil pitch" do
      events = [note_event(%{pitch: "C4"}), note_event(%{pitch: nil})]
      payload = AudioSync.build_play_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
    end

    test "excludes events with empty pitch" do
      events = [note_event(%{pitch: "C4"}), note_event(%{pitch: ""})]
      payload = AudioSync.build_play_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
    end

    test "excludes non note_on event types" do
      events = [
        note_event(%{event_type: "note_on", pitch: "C4"}),
        note_event(%{event_type: "rest", pitch: nil}),
        note_event(%{event_type: "chord", pitch: "E4"})
      ]

      payload = AudioSync.build_play_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
    end

    test "preserves start_time and duration" do
      events = [note_event(%{start_time: 1.25, duration: 0.75})]
      payload = AudioSync.build_play_payload(state(events: events), 120.0)
      [e] = payload.events
      assert e.start_time == 1.25
      assert e.duration == 0.75
    end

    test "returns empty events list when no valid notes" do
      payload = AudioSync.build_play_payload(state(events: []), 120.0)
      assert payload.events == []
    end
  end

  describe "build_pause_payload/1" do
    test "returns current_time from state" do
      assert AudioSync.build_pause_payload(state(current_time: 7.5)) == %{current_time: 7.5}
    end

    test "returns 0.0 when at start" do
      assert AudioSync.build_pause_payload(state(current_time: 0.0)) == %{current_time: 0.0}
    end
  end

  describe "build_stop_payload/0" do
    test "returns empty map" do
      assert AudioSync.build_stop_payload() == %{}
    end
  end

  describe "build_tempo_payload/2" do
    test "scales bpm and includes speed, current_time, and events" do
      events = [note_event()]

      payload =
        AudioSync.build_tempo_payload(state(speed: 2.0, current_time: 4.0, events: events), 100.0)

      assert payload.bpm == 200.0
      assert payload.speed == 2.0
      assert payload.current_time == 4.0
      assert length(payload.events) == 1
    end

    test "filters events the same way as build_play_payload" do
      events = [note_event(%{pitch: "C4"}), note_event(%{pitch: nil})]
      payload = AudioSync.build_tempo_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
    end
  end
end
