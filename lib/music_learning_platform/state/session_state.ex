defmodule MusicLearningPlatform.State.SessionState do
  alias MusicLearningPlatform.State.StateModel
  alias MusicLearningPlatform.Application.Visual.NotationConfig

  def get_notation_config(session_id) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      {:ok, state.notation_config}
    end
  end

  def toggle_notation_option(session_id, option) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      new_config = NotationConfig.toggle(state.notation_config, option)
      StateModel.update_notation_config(session_id, new_config)
    end
  end

  def get_current_time(session_id) do
    with {:ok, state} <- StateModel.get_state(session_id) do
      {:ok, state.current_time}
    end
  end
end
