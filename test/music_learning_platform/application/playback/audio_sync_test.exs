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
    test "returns scaled bpm at speed 1.0" do
      payload = AudioSync.build_play_payload(state(speed: 1.0), 120.0)
      assert payload.bpm == 120.0
    end

    test "scales bpm by speed factor" do
      assert AudioSync.build_play_payload(state(speed: 0.5), 120.0).bpm == 60.0
      assert AudioSync.build_play_payload(state(speed: 2.0), 120.0).bpm == 240.0
      assert AudioSync.build_play_payload(state(speed: 0.75), 120.0).bpm == 90.0
    end

    test "includes current_time" do
      payload = AudioSync.build_play_payload(state(speed: 1.5, current_time: 3.0), 100.0)
      assert payload.current_time == 3.0
    end

    test "does not include events" do
      payload = AudioSync.build_play_payload(state(events: [note_event()]), 120.0)
      refute Map.has_key?(payload, :events)
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

  describe "build_set_speed_payload/2" do
    test "returns scaled bpm" do
      payload = AudioSync.build_set_speed_payload(state(speed: 2.0), 100.0)
      assert payload.bpm == 200.0
    end

    test "rounds bpm to 2 decimal places" do
      payload = AudioSync.build_set_speed_payload(state(speed: 0.75), 100.0)
      assert payload.bpm == 75.0
    end

    test "does not include events" do
      payload =
        AudioSync.build_set_speed_payload(state(speed: 1.0, events: [note_event()]), 120.0)

      refute Map.has_key?(payload, :events)
    end
  end

  describe "build_load_events_payload/2" do
    test "includes base_bpm" do
      payload = AudioSync.build_load_events_payload(state(events: []), 120.0)
      assert payload.base_bpm == 120.0
    end

    test "serializes note_on events with pitch" do
      events = [note_event(%{pitch: "G4", index: 2, color_key: "#1E90FF"})]
      payload = AudioSync.build_load_events_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
      [e] = payload.events
      assert e.pitch == "G4"
      assert e.index == 2
      assert e.color_key == "#1E90FF"
    end

    test "preserves start_time and duration" do
      events = [note_event(%{start_time: 1.25, duration: 0.75})]
      payload = AudioSync.build_load_events_payload(state(events: events), 120.0)
      [e] = payload.events
      assert e.start_time == 1.25
      assert e.duration == 0.75
    end

    test "excludes events with nil pitch" do
      events = [note_event(%{pitch: "C4"}), note_event(%{pitch: nil})]
      payload = AudioSync.build_load_events_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
    end

    test "excludes events with empty pitch" do
      events = [note_event(%{pitch: "C4"}), note_event(%{pitch: ""})]
      payload = AudioSync.build_load_events_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
    end

    test "excludes non note_on event types" do
      events = [
        note_event(%{event_type: "note_on", pitch: "C4"}),
        note_event(%{event_type: "rest", pitch: nil}),
        note_event(%{event_type: "chord", pitch: "E4"})
      ]

      payload = AudioSync.build_load_events_payload(state(events: events), 120.0)
      assert length(payload.events) == 1
    end

    test "returns empty events list when no valid notes" do
      payload = AudioSync.build_load_events_payload(state(events: []), 120.0)
      assert payload.events == []
    end
  end
end
