defmodule MusicLearningPlatform.MusicLearning do
  alias MusicLearningPlatform.Application.Songs.{SongLibrary, SongLoaderService}
  alias MusicLearningPlatform.Application.Playback.{PlaybackController, TempoController}
  alias MusicLearningPlatform.Application.Sync.SyncEngine
  alias MusicLearningPlatform.Application.Visual.{ColorMapper, HighlightEngine}
  alias MusicLearningPlatform.State.{PlaybackState, SessionState}

  # Songs

  def list_songs, do: SongLibrary.list_published_songs()

  def get_song(id), do: SongLibrary.get_song_with_versions!(id)

  def list_song_versions(song_id), do: SongLibrary.list_song_versions(song_id)

  # Session

  def init_session(session_id, song_id, song_version_id) do
    with {:ok, events} <- SongLoaderService.load_timeline_events_for_version(song_version_id) do
      PlaybackState.create_session(session_id, song_id, song_version_id, events)
    end
  end

  def destroy_session(session_id), do: PlaybackState.destroy_session(session_id)

  # Playback

  def play(session_id), do: PlaybackController.play(session_id)
  def pause(session_id), do: PlaybackController.pause(session_id)
  def stop(session_id), do: PlaybackController.stop(session_id)
  def seek(session_id, position), do: PlaybackController.seek(session_id, position)

  # Tempo

  def set_speed(session_id, speed), do: TempoController.set_speed(session_id, speed)
  def increase_speed(session_id), do: TempoController.increase_speed(session_id)
  def decrease_speed(session_id), do: TempoController.decrease_speed(session_id)

  # Visual

  def toggle_notation(session_id, option),
    do: SessionState.toggle_notation_option(session_id, option)

  def get_notation_config(session_id), do: SessionState.get_notation_config(session_id)

  def build_highlights(active_events), do: HighlightEngine.build_highlight_payload(active_events)
  def note_color(pitch), do: ColorMapper.color_for_pitch(pitch)

  # Sync tick (called from LiveView on timer)

  def sync_tick(session_id, current_time), do: SyncEngine.tick(session_id, current_time)
end
