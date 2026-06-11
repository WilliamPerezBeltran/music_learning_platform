defmodule MusicLearningPlatform.Application.Playback.PlaybackController do
  alias MusicLearningPlatform.State.StateModel
  alias MusicLearningPlatform.Application.Sync.SyncEngine

  def play(session_id) do
    with {:ok, _state} <- StateModel.get_state(session_id),
         {:ok, state} <- StateModel.set_playing(session_id, true) do
      SyncEngine.start_sync(session_id, state)
      {:ok, state}
    end
  end

  def pause(session_id) do
    with {:ok, state} <- StateModel.set_playing(session_id, false) do
      SyncEngine.pause_sync(session_id)
      {:ok, state}
    end
  end

  def stop(session_id) do
    with {:ok, state} <- StateModel.reset_position(session_id) do
      SyncEngine.stop_sync(session_id)
      {:ok, state}
    end
  end

  def seek(session_id, position_seconds) do
    with {:ok, state} <- StateModel.set_position(session_id, position_seconds) do
      SyncEngine.seek_sync(session_id, position_seconds)
      {:ok, state}
    end
  end
end
