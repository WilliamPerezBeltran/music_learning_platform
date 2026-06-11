defmodule MusicLearningPlatform.Application.Songs.SongLibraryTest do
  use MusicLearningPlatform.DataCase, async: true

  alias MusicLearningPlatform.Application.Songs.SongLibrary

  defp song_attrs(overrides \\ %{}) do
    Map.merge(%{title: "Bartolito", category: "infantil", is_published: true}, overrides)
  end

  describe "create_song/1" do
    test "creates a song with valid attrs" do
      assert {:ok, song} = SongLibrary.create_song(song_attrs())
      assert song.title == "Bartolito"
      assert song.category == "infantil"
    end

    test "returns error with invalid attrs" do
      assert {:error, changeset} = SongLibrary.create_song(%{})
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "list_songs/0" do
    test "returns all songs ordered by title" do
      SongLibrary.create_song!(song_attrs(%{title: "Estrellita"}))
      SongLibrary.create_song!(song_attrs(%{title: "Bartolito"}))

      songs = SongLibrary.list_songs()
      titles = Enum.map(songs, & &1.title)
      assert titles == Enum.sort(titles)
    end
  end

  describe "list_published_songs/0" do
    test "returns only published songs" do
      SongLibrary.create_song!(song_attrs(%{title: "Published", is_published: true}))
      SongLibrary.create_song!(song_attrs(%{title: "Draft", is_published: false}))

      songs = SongLibrary.list_published_songs()
      assert Enum.all?(songs, & &1.is_published)
      assert Enum.any?(songs, &(&1.title == "Published"))
      refute Enum.any?(songs, &(&1.title == "Draft"))
    end
  end

  describe "get_song!/1" do
    test "returns the song" do
      {:ok, song} = SongLibrary.create_song(song_attrs())
      assert SongLibrary.get_song!(song.id).id == song.id
    end

    test "raises when not found" do
      assert_raise Ecto.NoResultsError, fn -> SongLibrary.get_song!(999_999) end
    end
  end

  describe "get_song_with_versions!/1" do
    test "preloads song_versions" do
      {:ok, song} = SongLibrary.create_song(song_attrs())

      SongLibrary.create_song_version!(%{
        song_id: song.id,
        version_type: "melody",
        level_index: 1,
        name: "Solo melodía",
        musicxml_path: "test.xml"
      })

      loaded = SongLibrary.get_song_with_versions!(song.id)
      assert length(loaded.song_versions) == 1
    end
  end

  describe "list_song_versions/1" do
    test "returns active versions ordered by level_index" do
      {:ok, song} = SongLibrary.create_song(song_attrs())

      SongLibrary.create_song_version!(%{
        song_id: song.id,
        version_type: "full",
        level_index: 4,
        name: "Completa",
        musicxml_path: "test.xml"
      })

      SongLibrary.create_song_version!(%{
        song_id: song.id,
        version_type: "melody",
        level_index: 1,
        name: "Melodía",
        musicxml_path: "test.xml"
      })

      versions = SongLibrary.list_song_versions(song.id)
      assert Enum.map(versions, & &1.level_index) == [1, 4]
    end
  end
end
