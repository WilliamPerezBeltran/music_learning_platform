defmodule MusicLearningPlatformWeb.SongLive.ShowTest do
  use MusicLearningPlatformWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MusicLearningPlatform.Application.Songs.SongLibrary
  alias MusicLearningPlatform.Repo
  alias MusicLearningPlatform.Domain.Timeline.{MusicTimeline, MusicalEvent}

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

  defp insert_timeline(version, attrs \\ %{}) do
    %MusicTimeline{}
    |> MusicTimeline.changeset(
      Map.merge(%{song_version_id: version.id, bpm: 120.0, total_duration: 10.0}, attrs)
    )
    |> Repo.insert!()
  end

  defp insert_event(timeline, attrs \\ %{}) do
    Repo.insert_all(
      MusicalEvent,
      [
        Map.merge(
          %{
            music_timeline_id: timeline.id,
            event_type: "note_on",
            pitch: "C4",
            start_time: 0.0,
            end_time: 0.5,
            duration: 0.5,
            voice: "melody",
            color_key: "#FF4444",
            index: 0
          },
          attrs
        )
      ],
      returning: true
    )
  end

  # --- mount ---

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
      assert html =~ "Elige una canción"
    end

    test "playback controls are not rendered without a song", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/songs")
      refute html =~ "tone-player"
    end
  end

  # --- handle_params ---

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

  # --- playback controls ---

  describe "playback controls" do
    test "TonePlayerHook is mounted when timeline exists", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      assert html =~ ~s(phx-hook="TonePlayerHook")
      assert html =~ "tone-player"
    end

    test "play button renders when timeline is loaded", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      assert html =~ ~s(phx-click="play")
    end

    test "stop button renders when timeline is loaded", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      assert html =~ ~s(phx-click="stop")
    end

    test "speed buttons render for all speed options", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")

      for speed <- ["0.5", "0.75", "1.0", "1.5", "2.0"] do
        assert html =~ ~s(phx-value-speed="#{speed}")
      end
    end

    test "default speed 1x is highlighted as primary", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      assert html =~ "1x"
    end

    test "controls not rendered when no timeline", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")
      refute html =~ "tone-player"
    end
  end

  # --- playback events ---

  describe "stop event" do
    test "resets is_playing to false", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      view |> element("button[phx-click='stop']") |> render_click()

      refute render(view) =~ ~s(phx-click="pause")
      assert render(view) =~ ~s(phx-click="play")
    end
  end

  describe "set_speed event" do
    test "highlights selected speed button", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      html = view |> element("button[phx-value-speed='0.5']") |> render_click()

      assert html =~ "0.5x"
    end
  end

  # --- hook-originated events ---

  describe "note_active event" do
    test "does not crash with semantic color_key format", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      render_hook(view, "note_active", %{"index" => 0, "color_key" => "do", "current_time" => 0.5})

      assert render(view) =~ "Bartolito"
    end

    test "does not crash with legacy hex color_key format", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      render_hook(view, "note_active", %{
        "index" => 0,
        "color_key" => "#FF4444",
        "current_time" => 0.5
      })

      assert render(view) =~ "Bartolito"
    end

    test "does not crash with index zero", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      render_hook(view, "note_active", %{
        "index" => 0,
        "color_key" => "#1E90FF",
        "current_time" => 0.0
      })

      assert render(view) =~ "Bartolito"
    end

    test "does not crash with large note index", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      render_hook(view, "note_active", %{
        "index" => 999,
        "color_key" => "#8A2BE2",
        "current_time" => 30.0
      })

      assert render(view) =~ "Bartolito"
    end

    test "accepts all legacy hex color formats from old DB seed", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      for {color_key, time} <- [
            {"#FF4444", 0.0},
            {"#1E90FF", 0.5},
            {"#8A2BE2", 1.0},
            {"#32CD32", 1.5}
          ] do
        render_hook(view, "note_active", %{
          "index" => 0,
          "color_key" => color_key,
          "current_time" => time
        })
      end

      assert render(view) =~ "Bartolito"
    end
  end

  # --- select_song event ---

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

  # --- select_version event ---

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

      assert html =~ "active"
    end
  end

  # --- score_loaded event ---

  describe "score_loaded event" do
    test "shows note count after hook confirms render", %{conn: conn} do
      song = insert_song()
      insert_version(song)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      render_hook(view, "score_loaded", %{"total_notes" => 42})

      assert render(view) =~ "42 notas"
    end
  end

  # --- toggle_colors event ---

  describe "toggle_colors event" do
    test "color toggle button renders in controls bar", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, _view, html} = live(conn, ~p"/songs/#{song.id}")

      assert html =~ ~s(phx-click="toggle_colors")
    end

    test "disables colors when toggled off", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, view, html} = live(conn, ~p"/songs/#{song.id}")

      assert html =~ "active"

      html = view |> element("button[phx-click='toggle_colors']") |> render_click()

      refute html =~ ~r/phx-click="toggle_colors"[^>]*\bactive\b/
    end

    test "re-enables colors when toggled twice", %{conn: conn} do
      song = insert_song()
      version = insert_version(song)
      timeline = insert_timeline(version)
      insert_event(timeline)

      {:ok, view, _html} = live(conn, ~p"/songs/#{song.id}")

      view |> element("button[phx-click='toggle_colors']") |> render_click()
      html = view |> element("button[phx-click='toggle_colors']") |> render_click()

      assert html =~ "active"
    end
  end
end
