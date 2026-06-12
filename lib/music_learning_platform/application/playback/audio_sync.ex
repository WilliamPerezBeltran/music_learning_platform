defmodule MusicLearningPlatform.Application.Playback.AudioSync do
  def build_load_events_payload(state, bpm_base) do
    %{
      base_bpm: bpm_base,
      events: serialize_events(state.events)
    }
  end

  def build_play_payload(state, bpm_base) do
    %{
      bpm: Float.round(bpm_base * state.speed, 2),
      current_time: state.current_time
    }
  end

  def build_pause_payload(state) do
    %{current_time: state.current_time}
  end

  def build_stop_payload, do: %{}

  def build_set_speed_payload(state, bpm_base) do
    %{bpm: Float.round(bpm_base * state.speed, 2)}
  end

  defp serialize_events(events) do
    events
    |> Enum.filter(&(&1.event_type == "note_on" && &1.pitch != nil && &1.pitch != ""))
    |> Enum.map(fn e ->
      %{
        pitch: e.pitch,
        start_time: e.start_time,
        duration: e.duration,
        index: e.index,
        color_key: e.color_key
      }
    end)
  end
end
