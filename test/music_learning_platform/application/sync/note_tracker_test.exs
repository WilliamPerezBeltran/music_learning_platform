defmodule MusicLearningPlatform.Application.Sync.NoteTrackerTest do
  use ExUnit.Case, async: true

  alias MusicLearningPlatform.Application.Sync.NoteTracker

  defp events do
    [
      %{index: 0, pitch: "C4", start_time: 0.0, end_time: 0.5, voice: "melody"},
      %{index: 1, pitch: "D4", start_time: 0.5, end_time: 1.0, voice: "melody"},
      %{index: 2, pitch: "E4", start_time: 1.0, end_time: 1.5, voice: "melody"},
      %{index: 3, pitch: "F4", start_time: 2.0, end_time: 2.5, voice: "melody"}
    ]
  end

  describe "get_active_events/3" do
    test "returns events active at current time" do
      active = NoteTracker.get_active_events("s1", 0.25, events())
      assert length(active) == 1
      assert hd(active).pitch == "C4"
    end

    test "returns event at its start boundary" do
      active = NoteTracker.get_active_events("s1", 0.5, events())
      pitches = Enum.map(active, & &1.pitch)
      assert "D4" in pitches
    end

    test "returns empty when no events are active" do
      active = NoteTracker.get_active_events("s1", 1.6, events())
      assert active == []
    end

    test "returns multiple simultaneous events" do
      simultaneous = [
        %{index: 0, pitch: "C4", start_time: 0.0, end_time: 1.0, voice: "right_hand"},
        %{index: 1, pitch: "E4", start_time: 0.0, end_time: 1.0, voice: "left_hand"}
      ]

      active = NoteTracker.get_active_events("s1", 0.5, simultaneous)
      assert length(active) == 2
    end
  end

  describe "get_upcoming_events/4" do
    test "returns events within the lookahead window" do
      upcoming = NoteTracker.get_upcoming_events("s1", 0.0, events(), 0.6)
      assert length(upcoming) == 1
      assert hd(upcoming).pitch == "D4"
    end

    test "returns empty when nothing is upcoming" do
      upcoming = NoteTracker.get_upcoming_events("s1", 2.5, events(), 0.1)
      assert upcoming == []
    end
  end
end
