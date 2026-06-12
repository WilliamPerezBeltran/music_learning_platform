defmodule MusicLearningPlatform.Application.Sync.NoteTrackerTest do
  use ExUnit.Case, async: true

  alias MusicLearningPlatform.Application.Sync.NoteTracker

  defp unique_session, do: "test_session_#{System.unique_integer([:positive])}"

  defp events do
    [
      %{index: 0, pitch: "C4", start_time: 0.0, end_time: 0.5, voice: "melody"},
      %{index: 1, pitch: "D4", start_time: 0.5, end_time: 1.0, voice: "melody"},
      %{index: 2, pitch: "E4", start_time: 1.0, end_time: 1.5, voice: "melody"},
      %{index: 3, pitch: "F4", start_time: 2.0, end_time: 2.5, voice: "melody"}
    ]
  end

  describe "set_active/2 and get_active/1" do
    test "stores and retrieves an active note index" do
      session = unique_session()
      NoteTracker.set_active(session, 5)
      assert {:ok, 5} = NoteTracker.get_active(session)
    end

    test "overwrites the previous active index" do
      session = unique_session()
      NoteTracker.set_active(session, 0)
      NoteTracker.set_active(session, 7)
      assert {:ok, 7} = NoteTracker.get_active(session)
    end

    test "returns error when no active note is set" do
      session = unique_session()
      assert {:error, :no_active_note} = NoteTracker.get_active(session)
    end

    test "sessions are isolated from each other" do
      s1 = unique_session()
      s2 = unique_session()
      NoteTracker.set_active(s1, 3)
      NoteTracker.set_active(s2, 9)
      assert {:ok, 3} = NoteTracker.get_active(s1)
      assert {:ok, 9} = NoteTracker.get_active(s2)
    end
  end

  describe "reset/1" do
    test "clears the active note for a session" do
      session = unique_session()
      NoteTracker.set_active(session, 2)
      NoteTracker.reset(session)
      assert {:error, :no_active_note} = NoteTracker.get_active(session)
    end

    test "is a no-op when session has no active note" do
      session = unique_session()
      assert :ok = NoteTracker.reset(session)
    end
  end

  describe "seek/3" do
    test "resets active note on seek" do
      session = unique_session()
      NoteTracker.set_active(session, 4)
      NoteTracker.seek(session, 1.0, events())
      assert {:error, :no_active_note} = NoteTracker.get_active(session)
    end
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
