defmodule MusicLearningPlatform.Application.Sync.NoteTracker do
  def reset(_session_id), do: :ok
  def seek(_session_id, _position, _events), do: :ok

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
