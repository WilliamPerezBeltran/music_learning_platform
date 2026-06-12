defmodule MusicLearningPlatform.Application.Visual.ColorMapperTest do
  use ExUnit.Case, async: true

  alias MusicLearningPlatform.Application.Visual.ColorMapper

  describe "get_color_key/1" do
    test "returns semantic key for each natural note" do
      assert ColorMapper.get_color_key("C4") == "do"
      assert ColorMapper.get_color_key("D4") == "re"
      assert ColorMapper.get_color_key("E4") == "mi"
      assert ColorMapper.get_color_key("F4") == "fa"
      assert ColorMapper.get_color_key("G4") == "sol"
      assert ColorMapper.get_color_key("A4") == "la"
      assert ColorMapper.get_color_key("B4") == "si"
    end

    test "returns same key regardless of octave" do
      assert ColorMapper.get_color_key("C3") == ColorMapper.get_color_key("C5")
    end

    test "returns same key for sharp notes as their natural" do
      assert ColorMapper.get_color_key("C#4") == "do"
      assert ColorMapper.get_color_key("F#4") == "fa"
    end

    test "returns nil for unknown pitch" do
      assert ColorMapper.get_color_key("X4") == nil
    end

    test "returns nil for nil" do
      assert ColorMapper.get_color_key(nil) == nil
    end

    test "returns nil for empty string" do
      assert ColorMapper.get_color_key("") == nil
    end
  end

  describe "color_for_pitch/1" do
    test "is an alias of get_color_key/1" do
      assert ColorMapper.color_for_pitch("C4") == ColorMapper.get_color_key("C4")
      assert ColorMapper.color_for_pitch(nil) == ColorMapper.get_color_key(nil)
    end
  end

  describe "get_hex/1" do
    test "returns correct hex for each color key" do
      assert ColorMapper.get_hex("do") == "#E53935"
      assert ColorMapper.get_hex("re") == "#FB8C00"
      assert ColorMapper.get_hex("mi") == "#FDD835"
      assert ColorMapper.get_hex("fa") == "#43A047"
      assert ColorMapper.get_hex("sol") == "#1E88E5"
      assert ColorMapper.get_hex("la") == "#8E24AA"
      assert ColorMapper.get_hex("si") == "#E91E63"
    end

    test "returns black for unknown key" do
      assert ColorMapper.get_hex("unknown") == "#000000"
    end
  end

  describe "all_colors/0" do
    test "returns a map with 7 entries" do
      colors = ColorMapper.all_colors()
      assert is_map(colors)
      assert map_size(colors) == 7
    end

    test "keys are semantic note names" do
      keys = ColorMapper.all_colors() |> Map.keys() |> Enum.sort()
      assert keys == ["do", "fa", "la", "mi", "re", "si", "sol"] |> Enum.sort()
    end
  end
end
