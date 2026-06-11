defmodule MusicLearningPlatform.Application.Visual.ColorMapperTest do
  use ExUnit.Case, async: true

  alias MusicLearningPlatform.Application.Visual.ColorMapper

  describe "color_for_pitch/1" do
    test "returns correct color for each natural note" do
      assert ColorMapper.color_for_pitch("C4") == "#FF4444"
      assert ColorMapper.color_for_pitch("D4") == "#FF8C00"
      assert ColorMapper.color_for_pitch("E4") == "#FFD700"
      assert ColorMapper.color_for_pitch("F4") == "#32CD32"
      assert ColorMapper.color_for_pitch("G4") == "#1E90FF"
      assert ColorMapper.color_for_pitch("A4") == "#8A2BE2"
      assert ColorMapper.color_for_pitch("B4") == "#FF69B4"
    end

    test "returns correct color for sharp notes" do
      assert ColorMapper.color_for_pitch("C#4") == "#FF6666"
      assert ColorMapper.color_for_pitch("F#4") == "#00FA9A"
    end

    test "ignores octave number" do
      assert ColorMapper.color_for_pitch("C3") == ColorMapper.color_for_pitch("C5")
    end

    test "returns fallback for unknown pitch" do
      assert ColorMapper.color_for_pitch("X4") == "#CCCCCC"
    end

    test "returns fallback for nil" do
      assert ColorMapper.color_for_pitch(nil) == "#CCCCCC"
    end
  end

  describe "all_colors/0" do
    test "returns a non-empty map" do
      colors = ColorMapper.all_colors()
      assert is_map(colors)
      assert map_size(colors) > 0
    end
  end
end
