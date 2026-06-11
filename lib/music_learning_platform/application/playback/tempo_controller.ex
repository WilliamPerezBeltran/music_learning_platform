defmodule MusicLearningPlatform.Application.Playback.TempoController do
  alias MusicLearningPlatform.State.StateModel

  @min_speed 0.5
  @max_speed 2.0

  def set_speed(session_id, speed) when speed >= @min_speed and speed <= @max_speed do
    StateModel.set_speed(session_id, speed)
  end

  def set_speed(_session_id, _speed), do: {:error, :invalid_speed}

  def increase_speed(session_id, step \\ 0.25) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      new_speed = min(state.speed + step, @max_speed)
      StateModel.set_speed(session_id, new_speed)
    end
  end

  def decrease_speed(session_id, step \\ 0.25) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      new_speed = max(state.speed - step, @min_speed)
      StateModel.set_speed(session_id, new_speed)
    end
  end
end
