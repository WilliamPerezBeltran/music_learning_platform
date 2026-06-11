defmodule MusicLearningPlatform.Domain.Songs.SongTest do
  use MusicLearningPlatform.DataCase, async: true

  alias MusicLearningPlatform.Domain.Songs.Song

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = Song.changeset(%Song{}, %{title: "Bartolito", category: "infantil"})
      assert changeset.valid?
    end

    test "valid with all fields" do
      attrs = %{
        title: "Bartolito",
        category: "infantil",
        artist: "Tradicional",
        description: "Canción infantil",
        duration_seconds: 24.0,
        is_published: true
      }

      assert Song.changeset(%Song{}, attrs).valid?
    end

    test "invalid without title" do
      changeset = Song.changeset(%Song{}, %{category: "infantil"})
      refute changeset.valid?
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid without category" do
      changeset = Song.changeset(%Song{}, %{title: "Bartolito"})
      refute changeset.valid?
      assert %{category: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid with empty title" do
      changeset = Song.changeset(%Song{}, %{title: "", category: "infantil"})
      refute changeset.valid?
    end
  end

  describe "persistence" do
    test "inserts a song" do
      {:ok, song} =
        %Song{}
        |> Song.changeset(%{title: "Estrellita", category: "infantil"})
        |> Repo.insert()

      assert song.id
      assert song.title == "Estrellita"
      assert song.is_published == false
    end
  end
end
