defmodule MusicLearningPlatform.State.PlaybackState do
  alias MusicLearningPlatform.State.StateModel

  def init_table do
    case :ets.whereis(:playback_states) do
      :undefined -> :ets.new(:playback_states, [:named_table, :public, :set])
      _ -> :playback_states
    end
  end

  def create_session(session_id, song_id, song_version_id, events) do
    state = StateModel.new(session_id, song_id, song_version_id, events)
    StateModel.put_state(state)
  end

  def destroy_session(session_id) do
    StateModel.delete_state(session_id)
  end

  def session_exists?(session_id) do
    case StateModel.get_state(session_id) do
      {:ok, _} -> true
      _ -> false
    end
  end
end
