defmodule MusicLearningPlatform.Application.Visual.NotationConfigTest do
  use ExUnit.Case, async: true

  alias MusicLearningPlatform.Application.Visual.NotationConfig

  describe "default/0" do
    test "all options enabled by default" do
      config = NotationConfig.default()
      assert config.colors_enabled
      assert config.note_names_enabled
      assert config.chords_enabled
      assert config.left_hand_enabled
      assert config.right_hand_enabled
      assert config.lyrics_enabled
    end
  end

  describe "toggle/2" do
    test "toggles colors off then on" do
      config = NotationConfig.default()
      assert NotationConfig.toggle(config, :colors).colors_enabled == false

      assert NotationConfig.toggle(config, :colors)
             |> NotationConfig.toggle(:colors)
             |> Map.get(:colors_enabled) == true
    end

    test "toggles note_names" do
      config = NotationConfig.default()
      refute NotationConfig.toggle(config, :note_names).note_names_enabled
    end

    test "toggles chords" do
      refute NotationConfig.default()
             |> NotationConfig.toggle(:chords)
             |> Map.get(:chords_enabled)
    end

    test "toggles left_hand" do
      refute NotationConfig.default()
             |> NotationConfig.toggle(:left_hand)
             |> Map.get(:left_hand_enabled)
    end

    test "toggles right_hand" do
      refute NotationConfig.default()
             |> NotationConfig.toggle(:right_hand)
             |> Map.get(:right_hand_enabled)
    end

    test "toggles lyrics" do
      refute NotationConfig.default()
             |> NotationConfig.toggle(:lyrics)
             |> Map.get(:lyrics_enabled)
    end
  end

  describe "from_map/1" do
    test "builds config from string-keyed map" do
      config = NotationConfig.from_map(%{"colors_enabled" => false, "lyrics_enabled" => false})
      refute config.colors_enabled
      refute config.lyrics_enabled
      assert config.note_names_enabled
    end

    test "uses defaults for missing keys" do
      config = NotationConfig.from_map(%{})
      assert config == NotationConfig.default()
    end
  end
end
