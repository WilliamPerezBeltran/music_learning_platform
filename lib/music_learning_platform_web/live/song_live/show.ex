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
      |> assign(:colors_enabled, true)

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

  def handle_event("toggle_colors", _, socket) do
    colors_enabled = !socket.assigns.colors_enabled

    {:noreply,
     socket
     |> assign(:colors_enabled, colors_enabled)
     |> push_event("toggle_colors", %{enabled: colors_enabled})}
  end

  # --- Tone.js → LiveView callbacks ---

  def handle_event(
        "note_active",
        %{"index" => index, "color_key" => color_key, "current_time" => current_time},
        socket
      ) do
    MusicLearning.note_active(socket.assigns.session_id, index, current_time)
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
      <style>
        .song-btn-active { background: linear-gradient(135deg,#E53935,#E91E63); box-shadow: 0 4px 20px -6px #E5393570; }
        .play-btn        { background: linear-gradient(135deg,#E53935,#FB8C00); box-shadow: 0 4px 20px -6px #E5393570; }
        .ctrl-glass {
          background: rgba(255,255,255,0.06);
          border: 1px solid rgba(255,255,255,0.1);
          border-radius: 9999px;
          color: rgba(255,255,255,0.75);
          transition: all 0.2s;
        }
        .ctrl-glass:hover  { background: rgba(255,255,255,0.12); color: white; }
        .ctrl-glass.active { background: linear-gradient(135deg,#E53935,#FB8C00); border-color: transparent; color: white; box-shadow: 0 0 16px -4px #E5393560; }
        .speed-active      { background: linear-gradient(135deg,#1E88E5,#8E24AA); border-color: transparent; color: white; box-shadow: 0 0 12px -4px #1E88E560; }
        .song-card { transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease; }
        .song-card:hover   { transform: translateY(-3px); border-color: rgba(229,57,53,0.35) !important; box-shadow: 0 12px 40px -12px rgba(229,57,53,0.25); }
      </style>

      <div class="flex flex-col md:flex-row min-h-dvh text-white" style="background:#07070e;">

        <%!-- Mobile overlay --%>
        <%= if @sidebar_open do %>
          <div id="sidebar-overlay" class="fixed inset-0 bg-black/60 backdrop-blur-sm z-20 md:hidden"
               phx-click="close_sidebar"></div>
        <% end %>

        <%!-- ── SIDEBAR ─────────────────────────────────────────── --%>
        <aside
          id="sidebar"
          class={[
            "fixed inset-y-0 left-0 z-30 w-72 flex flex-col transition-transform duration-200",
            "md:static md:translate-x-0 md:w-60 lg:w-64",
            if(@sidebar_open, do: "translate-x-0", else: "-translate-x-full md:translate-x-0")
          ]}
          style="background:#0d0d18;border-right:1px solid rgba(255,255,255,0.07);"
        >
          <%!-- Logo --%>
          <div class="px-5 py-5" style="border-bottom:1px solid rgba(255,255,255,0.06);">
            <a href="/" class="flex items-center gap-2.5 group">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center text-base flex-shrink-0"
                   style="background:linear-gradient(135deg,#E53935,#E91E63);">🎹</div>
              <span class="font-bold text-sm text-white group-hover:opacity-80 transition-opacity">PianoColor</span>
            </a>
          </div>

          <%!-- Section label + close --%>
          <div class="flex items-center justify-between px-5 pt-5 pb-3">
            <p class="text-[10px] uppercase tracking-[0.18em] font-semibold text-white/50">Canciones</p>
            <button class="md:hidden w-7 h-7 rounded-lg flex items-center justify-center text-white hover:opacity-70 transition-opacity"
                    style="background:rgba(255,255,255,0.08);"
                    phx-click="close_sidebar" aria-label="Cerrar menú">
              <.icon name="hero-x-mark" class="w-3.5 h-3.5" />
            </button>
          </div>

          <%!-- Song list --%>
          <div class="flex-1 overflow-y-auto px-3 pb-4 space-y-0.5">
            <%= for song <- @songs do %>
              <button
                id={"song-btn-#{song.id}"}
                phx-click="select_song"
                phx-value-id={song.id}
                class={[
                  "w-full text-left px-3 py-2.5 rounded-xl text-sm font-medium transition-all",
                  if(@selected_song && @selected_song.id == song.id,
                    do: "song-btn-active text-white",
                    else: "text-white hover:bg-white/[0.07]"
                  )
                ]}
              >
                <div class="flex items-center gap-2.5">
                  <span class="w-5 h-5 rounded-md flex items-center justify-center text-[10px] flex-shrink-0"
                        style={"background:#{if @selected_song && @selected_song.id == song.id, do: "rgba(255,255,255,0.2)", else: "rgba(255,255,255,0.08)"}"}>
                    🎵
                  </span>
                  {song.title}
                </div>
              </button>
            <% end %>
            <%= if @songs == [] do %>
              <p class="text-xs text-white/60 px-3 py-2">
                No hay canciones. Ejecuta <code class="text-white/80">seeds.exs</code>
              </p>
            <% end %>
          </div>

          <%!-- Color rainbow bar --%>
          <div class="px-5 py-4" style="border-top:1px solid rgba(255,255,255,0.06);">
            <p class="text-[9px] uppercase tracking-widest text-white/40 mb-2.5">Sistema de colores</p>
            <div class="flex gap-1.5">
              <%= for {note, hex} <- [{"Do","#E53935"},{"Re","#FB8C00"},{"Mi","#FDD835"},{"Fa","#43A047"},{"Sol","#1E88E5"},{"La","#8E24AA"},{"Si","#E91E63"}] do %>
                <div title={note} class="flex-1 h-1.5 rounded-full" style={"background:#{hex};"}></div>
              <% end %>
            </div>
          </div>
        </aside>

        <%!-- ── MAIN ──────────────────────────────────────────────── --%>
        <main class="flex-1 flex flex-col min-w-0" style="background:#0b0b17;">

          <%!-- Header --%>
          <div class="shrink-0 px-4 sm:px-6 py-3.5 flex items-center gap-3"
               style="border-bottom:1px solid rgba(255,255,255,0.07);background:rgba(11,11,23,0.95);backdrop-filter:blur(12px);">

            <button id="sidebar-toggle"
                    class="md:hidden w-8 h-8 rounded-lg flex items-center justify-center text-white hover:opacity-70 transition-opacity"
                    style="background:rgba(255,255,255,0.07);"
                    phx-click="toggle_sidebar" aria-label="Abrir menú">
              <.icon name="hero-bars-3" class="w-4 h-4" />
            </button>

            <%= if @selected_song do %>
              <div class="flex items-center gap-2 min-w-0">
                <h1 class="text-sm sm:text-base font-bold text-white truncate">{@selected_song.title}</h1>
                <%= if @score_loaded do %>
                  <span class="text-xs text-white/50 whitespace-nowrap hidden sm:block">· {@total_notes} notas</span>
                <% end %>
              </div>
              <%= if length(@versions) > 1 do %>
                <div class="flex gap-1.5 ml-1">
                  <%= for v <- @versions do %>
                    <button
                      id={"version-btn-#{v.id}"}
                      phx-click="select_version"
                      phx-value-id={v.id}
                      class={["px-3 py-1 text-[11px] font-bold transition-all ctrl-glass",
                              if(@selected_version && @selected_version.id == v.id, do: "active", else: "")]}
                    >
                      N{v.level_index}
                    </button>
                  <% end %>
                </div>
              <% end %>
            <% else %>
              <p class="text-white text-sm font-medium">Elige una canción</p>
            <% end %>

            <a href="/" class="ml-auto flex items-center gap-1.5 text-xs text-white/60 hover:text-white transition-colors hidden sm:flex">
              <.icon name="hero-arrow-left" class="w-3 h-3" />
              Inicio
            </a>
          </div>

          <%!-- Controls bar --%>
          <%= if @selected_song && @timeline_loaded do %>
            <div id="tone-player" phx-hook="TonePlayerHook"
                 class="shrink-0 flex items-center gap-2 px-4 sm:px-6 py-2.5"
                 style="border-bottom:1px solid rgba(255,255,255,0.06);background:rgba(11,11,23,0.8);">
              <%= if @is_playing do %>
                <button phx-click="pause" class="w-9 h-9 rounded-full flex items-center justify-center text-white ctrl-glass" aria-label="Pausar">
                  <.icon name="hero-pause" class="w-4 h-4" />
                </button>
              <% else %>
                <button phx-click="play" class="w-9 h-9 rounded-full flex items-center justify-center text-white play-btn" aria-label="Reproducir">
                  <.icon name="hero-play" class="w-4 h-4" />
                </button>
              <% end %>
              <button phx-click="stop" class="w-9 h-9 rounded-full flex items-center justify-center ctrl-glass" aria-label="Detener">
                <.icon name="hero-stop" class="w-4 h-4" />
              </button>
              <div class="ml-auto flex items-center gap-2">
                <button phx-click="toggle_colors"
                        class={["w-8 h-8 rounded-full flex items-center justify-center ctrl-glass", if(@colors_enabled, do: "active", else: "")]}
                        aria-label="Alternar colores">
                  <.icon name="hero-swatch" class="w-3.5 h-3.5" />
                </button>
                <div class="w-px h-4 mx-1" style="background:rgba(255,255,255,0.1);"></div>
                <div class="flex items-center gap-1">
                  <%= for s <- @speeds do %>
                    <button phx-click="set_speed" phx-value-speed={s}
                            class={["px-2.5 py-1 text-[11px] font-bold ctrl-glass", if(@speed == s, do: "speed-active", else: "")]}>
                      {speed_label(s)}
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <%!-- Body: song grid + score --%>
          <div class="flex-1 overflow-auto p-4 sm:p-6">

            <%!-- Song grid — always visible when there are songs --%>
            <%= if @songs != [] do %>
              <div class="mb-6">
                <p class="text-[10px] uppercase tracking-[0.18em] font-semibold text-white/50 mb-4">Canciones disponibles</p>
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
                  <%= for song <- @songs do %>
                    <button
                      phx-click="select_song"
                      phx-value-id={song.id}
                      class="song-card text-left rounded-2xl p-5 flex flex-col gap-3"
                      style={"background:rgba(255,255,255,0.04);border:1px solid #{if @selected_song && @selected_song.id == song.id, do: "rgba(229,57,53,0.5)", else: "rgba(255,255,255,0.08)"};#{if @selected_song && @selected_song.id == song.id, do: "box-shadow:0 0 30px -8px rgba(229,57,53,0.3);", else: ""}"}
                    >
                      <div class="flex items-start justify-between gap-2">
                        <div class="w-10 h-10 rounded-xl flex items-center justify-center text-xl flex-shrink-0"
                             style={"#{if @selected_song && @selected_song.id == song.id, do: "background:linear-gradient(135deg,#E53935,#E91E63);", else: "background:rgba(255,255,255,0.07);"}"}> 🎵</div>
                        <%= if @selected_song && @selected_song.id == song.id do %>
                          <span class="text-[10px] font-bold px-2 py-0.5 rounded-full text-white"
                                style="background:linear-gradient(135deg,#E53935,#E91E63);">Activa</span>
                        <% end %>
                      </div>
                      <div>
                        <p class="font-bold text-white text-base leading-snug">{song.title}</p>
                        <%= if song.artist do %>
                          <p class="text-white/60 text-xs mt-0.5">{song.artist}</p>
                        <% end %>
                        <%= if song.category do %>
                          <p class="text-white/40 text-[10px] mt-1 uppercase tracking-wider">{song.category}</p>
                        <% end %>
                      </div>
                      <div class="flex gap-1 mt-auto">
                        <%= for {_n, hex} <- [{"Do","#E53935"},{"Re","#FB8C00"},{"Mi","#FDD835"},{"Fa","#43A047"},{"Sol","#1E88E5"},{"La","#8E24AA"},{"Si","#E91E63"}] do %>
                          <div class="flex-1 h-1 rounded-full opacity-40" style={"background:#{hex};"}></div>
                        <% end %>
                      </div>
                    </button>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%!-- Score --%>
            <%= if @selected_song do %>
              <div>
                <p class="text-[10px] uppercase tracking-[0.18em] font-semibold text-white/50 mb-4">Partitura</p>
                <div class="rounded-2xl overflow-hidden shadow-2xl shadow-black/50" style="background:white;min-height:300px;">
                  <div id="score-container" phx-hook="OsmdHook" phx-update="ignore" class="w-full min-h-72"></div>
                </div>
              </div>
            <% else %>
              <%= if @songs == [] do %>
                <div class="flex flex-col items-center justify-center h-64 gap-4">
                  <div class="w-16 h-16 rounded-2xl flex items-center justify-center text-3xl"
                       style="background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.08);">🎵</div>
                  <p class="text-white/60 text-sm">No hay canciones. Ejecuta <code class="text-white/80">seeds.exs</code></p>
                </div>
              <% end %>
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
