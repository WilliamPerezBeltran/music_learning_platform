defmodule MusicLearningPlatformWeb.SongLive.Show do
  use MusicLearningPlatformWeb, :live_view

  alias MusicLearningPlatform.MusicLearning
  alias MusicLearningPlatform.Application.Playback.AudioSync

  @speeds [0.5, 0.75, 1.0, 1.5, 2.0]

  @impl true
  def mount(_params, _session, socket) do
    session_id = "session_#{System.unique_integer([:positive])}"

    socket =
      socket
      |> assign(:songs, MusicLearning.list_songs())
      |> assign(:selected_song, nil)
      |> assign(:selected_version, nil)
      |> assign(:versions, [])
      |> assign(:score_loaded, false)
      |> assign(:total_notes, 0)
      |> assign(:sidebar_open, false)
      |> assign(:session_id, session_id)
      |> assign(:is_playing, false)
      |> assign(:speed, 1.0)
      |> assign(:current_time, 0.0)
      |> assign(:bpm, 120.0)
      |> assign(:timeline_loaded, false)
      |> assign(:speeds, @speeds)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    song = MusicLearning.get_song(String.to_integer(id))
    versions = MusicLearning.list_song_versions(song.id)
    first_version = List.first(versions)

    socket =
      socket
      |> assign(:selected_song, song)
      |> assign(:versions, versions)
      |> assign(:selected_version, first_version)
      |> assign(:score_loaded, false)
      |> assign(:is_playing, false)
      |> assign(:current_time, 0.0)
      |> assign(:timeline_loaded, false)
      |> push_event("stop", %{})

    socket =
      if first_version do
        socket
        |> push_musicxml(first_version.id)
        |> init_playback_session(song.id, first_version.id)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  # --- Song / version selection ---

  @impl true
  def handle_event("select_song", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/songs/#{id}")}
  end

  def handle_event("select_version", %{"id" => id}, socket) do
    version_id = String.to_integer(id)
    version = Enum.find(socket.assigns.versions, &(&1.id == version_id))

    socket =
      socket
      |> assign(:selected_version, version)
      |> assign(:score_loaded, false)
      |> assign(:is_playing, false)
      |> assign(:current_time, 0.0)
      |> assign(:timeline_loaded, false)
      |> push_event("stop", %{})
      |> push_musicxml(version_id)
      |> init_playback_session(socket.assigns.selected_song.id, version_id)

    {:noreply, socket}
  end

  # --- OSMD events ---

  def handle_event("score_loaded", %{"total_notes" => total}, socket) do
    {:noreply, assign(socket, score_loaded: true, total_notes: total)}
  end

  # --- Sidebar ---

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: !socket.assigns.sidebar_open)}
  end

  def handle_event("close_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: false)}
  end

  # --- Playback controls ---

  def handle_event("play", _, socket) do
    session_id = socket.assigns.session_id

    case MusicLearning.play(session_id) do
      {:ok, state} ->
        payload = AudioSync.build_play_payload(state, socket.assigns.bpm)
        {:noreply, socket |> assign(:is_playing, true) |> push_event("play", payload)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("pause", _, socket) do
    session_id = socket.assigns.session_id

    case MusicLearning.pause(session_id) do
      {:ok, state} ->
        payload = AudioSync.build_pause_payload(state)
        {:noreply, socket |> assign(:is_playing, false) |> push_event("pause", payload)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("stop", _, socket) do
    MusicLearning.stop(socket.assigns.session_id)

    socket =
      socket
      |> assign(:is_playing, false)
      |> assign(:current_time, 0.0)
      |> push_event("stop", AudioSync.build_stop_payload())

    {:noreply, socket}
  end

  def handle_event("set_speed", %{"speed" => speed_str}, socket) do
    speed = parse_speed(speed_str)
    session_id = socket.assigns.session_id

    case MusicLearning.set_speed(session_id, speed) do
      {:ok, state} ->
        payload = AudioSync.build_set_speed_payload(state, socket.assigns.bpm)
        {:noreply, socket |> assign(:speed, speed) |> push_event("set_speed", payload)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  # --- Tone.js → LiveView callbacks ---

  def handle_event("note_active", %{"index" => index, "color_key" => color_key}, socket) do
    {:noreply, push_event(socket, "highlight_note", %{index: index, color_key: color_key})}
  end

  # --- Private helpers ---

  defp push_musicxml(socket, version_id) do
    case MusicLearning.get_musicxml_content(version_id) do
      {:ok, content} -> push_event(socket, "load_score", %{musicxml: content})
      {:error, _} -> socket
    end
  end

  defp init_playback_session(socket, song_id, version_id) do
    session_id = socket.assigns.session_id

    with {:ok, state} <- MusicLearning.init_session(session_id, song_id, version_id),
         {:ok, timeline} <- MusicLearning.get_timeline_for_version(version_id) do
      payload = AudioSync.build_load_events_payload(state, timeline.bpm)

      socket
      |> assign(timeline_loaded: true, bpm: timeline.bpm)
      |> push_event("load_events", payload)
    else
      _ -> socket
    end
  end

  defp parse_speed(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> 1.0
    end
  end

  # --- Render ---

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.player flash={@flash}>
      <div class="flex flex-col md:flex-row min-h-dvh">
        <%!-- Overlay mobile --%>
        <%= if @sidebar_open do %>
          <div
            id="sidebar-overlay"
            class="fixed inset-0 bg-black/40 z-20 md:hidden"
            phx-click="close_sidebar"
          >
          </div>
        <% end %>

        <%!-- Sidebar --%>
        <aside
          id="sidebar"
          class={[
            "fixed inset-y-0 left-0 z-30 w-72 bg-base-100 border-r border-base-300",
            "flex flex-col gap-2 p-4 overflow-y-auto transition-transform duration-200",
            "md:static md:translate-x-0 md:w-56 lg:w-64 xl:w-72",
            if(@sidebar_open, do: "translate-x-0", else: "-translate-x-full md:translate-x-0")
          ]}
        >
          <div class="flex items-center justify-between mb-2">
            <h2 class="text-sm font-semibold uppercase tracking-wider text-base-content/60">
              Canciones
            </h2>
            <button
              class="md:hidden btn btn-ghost btn-xs"
              phx-click="close_sidebar"
              aria-label="Cerrar menú"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </button>
          </div>

          <%= for song <- @songs do %>
            <button
              id={"song-btn-#{song.id}"}
              phx-click="select_song"
              phx-value-id={song.id}
              class={[
                "w-full text-left px-3 py-2 rounded-lg text-sm transition-colors",
                if(@selected_song && @selected_song.id == song.id,
                  do: "bg-primary text-primary-content",
                  else: "hover:bg-base-200"
                )
              ]}
            >
              {song.title}
            </button>
          <% end %>

          <%= if @songs == [] do %>
            <p class="text-xs text-base-content/40">
              No hay canciones. Ejecuta <code>mix run priv/repo/seeds.exs</code>
            </p>
          <% end %>
        </aside>

        <%!-- Main --%>
        <main class="flex-1 flex flex-col min-w-0">
          <%!-- Header --%>
          <div class="shrink-0 border-b border-base-300 px-3 sm:px-6 py-3 flex items-center gap-3">
            <button
              id="sidebar-toggle"
              class="md:hidden btn btn-ghost btn-sm"
              phx-click="toggle_sidebar"
              aria-label="Abrir menú"
            >
              <.icon name="hero-bars-3" class="w-5 h-5" />
            </button>

            <%= if @selected_song do %>
              <h1 class="text-base sm:text-lg font-semibold truncate">{@selected_song.title}</h1>

              <%= if length(@versions) > 1 do %>
                <div class="flex flex-wrap gap-1 sm:gap-2">
                  <%= for v <- @versions do %>
                    <button
                      id={"version-btn-#{v.id}"}
                      phx-click="select_version"
                      phx-value-id={v.id}
                      class={[
                        "px-2 sm:px-3 py-1 rounded text-xs font-medium transition-colors",
                        if(@selected_version && @selected_version.id == v.id,
                          do: "bg-primary text-primary-content",
                          else: "bg-base-200 hover:bg-base-300"
                        )
                      ]}
                    >
                      N{v.level_index}
                    </button>
                  <% end %>
                </div>
              <% end %>

              <%= if @score_loaded do %>
                <span class="ml-auto text-xs text-base-content/40 whitespace-nowrap">
                  {@total_notes} notas
                </span>
              <% end %>
            <% else %>
              <p class="text-base-content/50 text-sm">Selecciona una canción</p>
            <% end %>
          </div>

          <%!-- Playback controls (visible when timeline is loaded) --%>
          <%= if @selected_song && @timeline_loaded do %>
            <div
              id="tone-player"
              phx-hook="TonePlayerHook"
              class="shrink-0 flex items-center gap-2 px-3 sm:px-6 py-2 border-b border-base-300 bg-base-200/50"
            >
              <%= if @is_playing do %>
                <button phx-click="pause" class="btn btn-sm btn-ghost" aria-label="Pausar">
                  <.icon name="hero-pause" class="w-5 h-5" />
                </button>
              <% else %>
                <button phx-click="play" class="btn btn-sm btn-primary" aria-label="Reproducir">
                  <.icon name="hero-play" class="w-5 h-5" />
                </button>
              <% end %>

              <button phx-click="stop" class="btn btn-sm btn-ghost" aria-label="Detener">
                <.icon name="hero-stop" class="w-5 h-5" />
              </button>

              <div class="ml-auto flex items-center gap-1">
                <%= for s <- @speeds do %>
                  <button
                    phx-click="set_speed"
                    phx-value-speed={s}
                    class={["btn btn-xs", if(@speed == s, do: "btn-primary", else: "btn-ghost")]}
                  >
                    {speed_label(s)}
                  </button>
                <% end %>
              </div>
            </div>
          <% end %>

          <%!-- Score --%>
          <div class="flex-1 p-2 sm:p-4 bg-white dark:bg-base-100">
            <%= if @selected_song do %>
              <div
                id="score-container"
                phx-hook="OsmdHook"
                phx-update="ignore"
                class="w-full min-h-48 sm:min-h-64"
              >
              </div>
            <% else %>
              <div class="flex items-center justify-center h-full min-h-48 text-base-content/30 text-sm">
                Selecciona una canción para ver la partitura
              </div>
            <% end %>
          </div>
        </main>
      </div>
    </Layouts.player>
    """
  end

  defp speed_label(1.0), do: "1x"
  defp speed_label(s), do: "#{s}x"
end
