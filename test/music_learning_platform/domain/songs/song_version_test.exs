defmodule MusicLearningPlatform.Domain.Songs.SongVersionTest do
  use MusicLearningPlatform.DataCase, async: true

  alias MusicLearningPlatform.Domain.Songs.{Song, SongVersion}

  defp insert_song do
    %Song{}
    |> Song.changeset(%{title: "Test Song", category: "infantil"})
    |> Repo.insert!()
  end

  describe "changeset/2" do
    test "valid with required fields" do
      song = insert_song()

      attrs = %{
        song_id: song.id,
        version_type: "melody",
        level_index: 1,
        name: "Solo melodía",
        musicxml_path: "test_level1.xml"
      }

      assert SongVersion.changeset(%SongVersion{}, attrs).valid?
    end

    test "invalid without song_id" do
      attrs = %{version_type: "melody", level_index: 1, name: "Test", musicxml_path: "test.xml"}
      changeset = SongVersion.changeset(%SongVersion{}, attrs)
      refute changeset.valid?
      assert %{song_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid with unknown version_type" do
      song = insert_song()

      attrs = %{
        song_id: song.id,
        version_type: "unknown",
        level_index: 1,
        name: "Test",
        musicxml_path: "test.xml"
      }

      changeset = SongVersion.changeset(%SongVersion{}, attrs)
      refute changeset.valid?
      assert %{version_type: ["is invalid"]} = errors_on(changeset)
    end

    test "invalid with level_index < 1" do
      song = insert_song()

      attrs = %{
        song_id: song.id,
        version_type: "melody",
        level_index: 0,
        name: "Test",
        musicxml_path: "test.xml"
      }

      changeset = SongVersion.changeset(%SongVersion{}, attrs)
      refute changeset.valid?
    end

    test "invalid with difficulty_score > 100" do
      song = insert_song()

      attrs = %{
        song_id: song.id,
        version_type: "melody",
        level_index: 1,
        name: "Test",
        musicxml_path: "test.xml",
        difficulty_score: 150
      }

      changeset = SongVersion.changeset(%SongVersion{}, attrs)
      refute changeset.valid?
    end

    test "accepts all valid version_types" do
      song = insert_song()

      for type <- ~w(melody simplified chords full custom) do
        attrs = %{
          song_id: song.id,
          version_type: type,
          level_index: 1,
          name: "Test",
          musicxml_path: "test.xml"
        }

        assert SongVersion.changeset(%SongVersion{}, attrs).valid?
      end
    end
  end
end
