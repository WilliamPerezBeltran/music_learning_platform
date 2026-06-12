defmodule MusicLearningPlatform.Application.Visual.ColorMapper do
  @color_keys %{
    "C" => "do",
    "D" => "re",
    "E" => "mi",
    "F" => "fa",
    "G" => "sol",
    "A" => "la",
    "B" => "si"
  }

  @hex_colors %{
    "do" => "#E53935",
    "re" => "#FB8C00",
    "mi" => "#FDD835",
    "fa" => "#43A047",
    "sol" => "#1E88E5",
    "la" => "#8E24AA",
    "si" => "#E91E63"
  }

  def get_color_key(pitch) when is_binary(pitch) and pitch != "" do
    case Regex.run(~r/^([A-G])/, pitch) do
      [_, note] -> Map.get(@color_keys, note)
      _ -> nil
    end
  end

  def get_color_key(_), do: nil

  def color_for_pitch(pitch), do: get_color_key(pitch)

  def get_hex(color_key), do: Map.get(@hex_colors, color_key, "#000000")

  def all_colors, do: @hex_colors
end
