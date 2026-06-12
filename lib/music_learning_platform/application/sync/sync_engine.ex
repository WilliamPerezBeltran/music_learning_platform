defmodule MusicLearningPlatform.Application.Sync.SyncEngine do
  alias MusicLearningPlatform.Application.Sync.{TimeCoordinator, NoteTracker}
  alias MusicLearningPlatform.State.StateModel

  def start_sync(session_id, state) do
    TimeCoordinator.start(session_id, state.current_time, state.speed)
    NoteTracker.reset(session_id)
    :ok
  end

  def pause_sync(session_id) do
    TimeCoordinator.stop(session_id)
    :ok
  end

  def stop_sync(session_id) do
    TimeCoordinator.stop(session_id)
    NoteTracker.reset(session_id)
    :ok
  end

  def seek_sync(session_id, position_seconds) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      TimeCoordinator.seek(session_id, position_seconds)
      NoteTracker.seek(session_id, position_seconds, state.events)
      :ok
    end
  end

  # Called when Tone.js reports a note playing — updates position + active note tracker
  def note_active(session_id, note_index, current_time) do
    NoteTracker.set_active(session_id, note_index)
    StateModel.set_position(session_id, current_time)
    :ok
  end

  def tick(session_id, current_time) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      active_events = NoteTracker.get_active_events(session_id, current_time, state.events)
      StateModel.set_position(session_id, current_time)
      {:ok, active_events}
    end
  end
end
