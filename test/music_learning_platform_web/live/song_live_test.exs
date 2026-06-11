defmodule MusicLearningPlatformWeb.SongLive.ShowTest do
  use MusicLearningPlatformWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MusicLearningPlatform.Application.Songs.SongLibrary

  defp insert_song(attrs \\ %{}) do
    SongLibrary.create_song!(
      Map.merge(%{title: "Bartolito", category: "infantil", is_published: true}, attrs)
    )
  end

  defp insert_version(song, attrs \\ %{}) do
    SongLibrary.create_song_version!(
      Map.merge(
        %{
          song_id: song.id,
          version_type: "melody",
          level_index: 1,
          name: "Solo melodía",
          musicxml_path: "bartolito_level1.xml"
        },
        attrs
      )
    )
  end

  describe "mount — /songs" do
    test "renders without crashing", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/songs")
      assert html =~ "Canciones"
    end

    test "shows empty state message when no songs exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/songs")
      assert html =~ "mix run priv/repo/seeds.exs"
    end

    test "shows song titles in sidebar", %{conn: conn} do
      insert_song(%{title: "Estrellita"})
      insert_song(%{title: "Bartolito"})

      {:ok, _view, html} = live(conn, ~p"/songs")
      assert html =~ "Estrellita"
      assert html =~ "Bartolito"
    end

    test "shows placeholder when no song selected", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/songs")
      assert html =~ "Selecciona una canción"
    end
  end

  describe "handle_params — /songs/:id" do
    test "renders song title in header", %{conn: conn} do
      song = insert_song(%{title: "Estrellita"})
      insert_version(song)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      assert html =~ "Estrellita"
    end

    test "renders score container when song has versions", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      assert html =~ "score-container"
    end

    test "score container has OsmdHook", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      assert html =~ ~s(phx-hook="OsmdHook")
    end

    test "score container has phx-update=ignore", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      assert html =~ ~s(phx-update="ignore")
    end
  end

  describe "select_song event" do
    test "navigates to song page", %{conn: conn} do
      song = insert_song(%{title: "Los Pollitos"})
      insert_version(song)

      {:ok, view, _html} = live(conn, ~p"/songs")
      assert has_element?(view, "#song-btn-#{song.id}")

      view |> element("#song-btn-#{song.id}") |> render_click()

      assert_patch(view, ~p"/songs/#{song.id}")
    end
  end

  describe "select_version event" do
    test "highlights selected version button", %{conn: conn} do
      song = insert_song()
      _v1 = insert_version(song, %{version_type: "melody", level_index: 1, name: "Melodía"})

      v2 =
        insert_version(song, %{
          version_type: "simplified",
          level_index: 2,
          name: "Simplificada"
        })

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      assert has_element?(view, "#version-btn-#{v2.id}")

      html = view |> element("#version-btn-#{v2.id}") |> render_click()

      assert html =~ "bg-primary"
    end
  end

  describe "score_loaded event" do
    test "shows note count after hook confirms render", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      render_hook(view, "score_loaded", %{"total_notes" => 42})

      assert render(view) =~ "42 notas"
    end
  end
end
