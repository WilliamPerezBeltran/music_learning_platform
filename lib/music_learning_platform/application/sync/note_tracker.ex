defmodule MusicLearningPlatform.Application.Sync.NoteTracker do
  @table :note_tracker

  def init_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:named_table, :public, :set])
      _ -> @table
    end
  end

  def set_active(session_id, note_index) do
    if table_exists?(), do: :ets.insert(@table, {session_id, note_index})
    :ok
  end

  def get_active(session_id) do
    if table_exists?() do
      case :ets.lookup(@table, session_id) do
        [{^session_id, index}] -> {:ok, index}
        [] -> {:error, :no_active_note}
      end
    else
      {:error, :no_active_note}
    end
  end

  def reset(session_id) do
    if table_exists?(), do: :ets.delete(@table, session_id)
    :ok
  end

  defp table_exists?, do: :ets.whereis(@table) != :undefined

  def seek(session_id, _position, _events) do
    reset(session_id)
  end

  def get_active_events(_session_id, current_time, events) do
    Enum.filter(events, fn event ->
      event.start_time <= current_time and event.end_time >= current_time
    end)
  end

  def get_upcoming_events(_session_id, current_time, events, lookahead_seconds \\ 0.5) do
    Enum.filter(events, fn event ->
      event.start_time > current_time and event.start_time <= current_time + lookahead_seconds
    end)
  end
end
