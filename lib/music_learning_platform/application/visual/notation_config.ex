defmodule MusicLearningPlatform.Application.Visual.NotationConfig do
  defstruct colors_enabled: true,
            note_names_enabled: true,
            chords_enabled: true,
            left_hand_enabled: true,
            right_hand_enabled: true,
            lyrics_enabled: true

  def default, do: %__MODULE__{}

  def toggle(config, :colors), do: %{config | colors_enabled: !config.colors_enabled}
  def toggle(config, :note_names), do: %{config | note_names_enabled: !config.note_names_enabled}
  def toggle(config, :chords), do: %{config | chords_enabled: !config.chords_enabled}
  def toggle(config, :left_hand), do: %{config | left_hand_enabled: !config.left_hand_enabled}
  def toggle(config, :right_hand), do: %{config | right_hand_enabled: !config.right_hand_enabled}
  def toggle(config, :lyrics), do: %{config | lyrics_enabled: !config.lyrics_enabled}

  def from_map(map) do
    %__MODULE__{
      colors_enabled: Map.get(map, "colors_enabled", true),
      note_names_enabled: Map.get(map, "note_names_enabled", true),
      chords_enabled: Map.get(map, "chords_enabled", true),
      left_hand_enabled: Map.get(map, "left_hand_enabled", true),
      right_hand_enabled: Map.get(map, "right_hand_enabled", true),
      lyrics_enabled: Map.get(map, "lyrics_enabled", true)
    }
  end
end
