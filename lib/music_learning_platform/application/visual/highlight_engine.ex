defmodule MusicLearningPlatform.Application.Visual.HighlightEngine do
  alias MusicLearningPlatform.Application.Visual.ColorMapper

  def build_highlight_payload(active_events) do
    Enum.map(active_events, fn event ->
      %{
        index: event.index,
        pitch: event.pitch,
        color: ColorMapper.color_for_pitch(event.pitch),
        voice: event.voice
      }
    end)
  end

  def clear_payload, do: []
end
