defmodule MusicLearningPlatform.Application.Sync.TimeCoordinator do
  alias MusicLearningPlatform.State.StateModel

  def start(session_id, from_position, speed) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      StateModel.put_state(%{state | current_time: from_position, speed: speed, is_playing: true})
      :ok
    end
  end

  def stop(session_id) do
    with {:ok, _} <- StateModel.set_playing(session_id, false), do: :ok
  end

  def seek(session_id, position_seconds) do
    with {:ok, _} <- StateModel.set_position(session_id, position_seconds), do: :ok
  end

  def current_position(session_id) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      {:ok, state.current_time}
    end
  end

  def elapsed_since(started_at, speed) do
    now = System.monotonic_time(:millisecond)
    (now - started_at) / 1000.0 * speed
  end
end
