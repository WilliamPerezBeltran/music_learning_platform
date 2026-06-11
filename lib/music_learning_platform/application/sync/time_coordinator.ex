defmodule MusicLearningPlatform.Application.Sync.TimeCoordinator do
  def start(_session_id, _from_position, _speed), do: :ok
  def stop(_session_id), do: :ok
  def seek(_session_id, _position_seconds), do: :ok

  def elapsed_since(started_at, speed) do
    now = System.monotonic_time(:millisecond)
    (now - started_at) / 1000.0 * speed
  end
end
