defmodule MusicLearningPlatform.State.StateModel do
  defstruct session_id: nil,
            song_id: nil,
            song_version_id: nil,
            current_time: 0.0,
            is_playing: false,
            speed: 1.0,
            loop_enabled: false,
            events: [],
            notation_config: nil

  def new(session_id, song_id, song_version_id, events) do
    alias MusicLearningPlatform.Application.Visual.NotationConfig

    %__MODULE__{
      session_id: session_id,
      song_id: song_id,
      song_version_id: song_version_id,
      events: events,
      notation_config: NotationConfig.default()
    }
  end

  def get_state(session_id) do
    case :ets.lookup(:playback_states, session_id) do
      [{^session_id, state}] -> {:ok, state}
      [] -> {:error, :not_found}
    end
  end

  def put_state(state) do
    :ets.insert(:playback_states, {state.session_id, state})
    {:ok, state}
  end

  def delete_state(session_id) do
    :ets.delete(:playback_states, session_id)
    :ok
  end

  def set_playing(session_id, playing) do
    with {:ok, state} <- get_state(session_id) do
      put_state(%{state | is_playing: playing})
    end
  end

  def set_position(session_id, time) do
    with {:ok, state} <- get_state(session_id) do
      put_state(%{state | current_time: time})
    end
  end

  def reset_position(session_id) do
    with {:ok, state} <- get_state(session_id) do
      put_state(%{state | current_time: 0.0, is_playing: false})
    end
  end

  def set_speed(session_id, speed) do
    with {:ok, state} <- get_state(session_id) do
      put_state(%{state | speed: speed})
    end
  end

  def update_notation_config(session_id, config) do
    with {:ok, state} <- get_state(session_id) do
      put_state(%{state | notation_config: config})
    end
  end
end
