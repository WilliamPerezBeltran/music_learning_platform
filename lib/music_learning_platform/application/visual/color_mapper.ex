defmodule MusicLearningPlatform.Application.Visual.ColorMapper do
  @note_colors %{
    "C" => "#FF4444",
    "D" => "#FF8C00",
    "E" => "#FFD700",
    "F" => "#32CD32",
    "G" => "#1E90FF",
    "A" => "#8A2BE2",
    "B" => "#FF69B4",
    "C#" => "#FF6666",
    "D#" => "#FFA500",
    "F#" => "#00FA9A",
    "G#" => "#00BFFF",
    "A#" => "#DA70D6"
  }

  def color_for_pitch(pitch) when is_binary(pitch) do
    note_class = extract_note_class(pitch)
    Map.get(@note_colors, note_class, "#CCCCCC")
  end

  def color_for_pitch(_), do: "#CCCCCC"

  def all_colors, do: @note_colors

  defp extract_note_class(pitch) do
    case Regex.run(~r/^([A-G][#b]?)/, pitch) do
      [_, note_class] -> note_class
      _ -> pitch
    end
  end
end
