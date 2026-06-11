defmodule MusicLearningPlatform.Application.Songs.SongLoaderService do
  alias MusicLearningPlatform.Application.Songs.SongLibrary
  alias MusicLearningPlatform.Infrastructure.MusicXML.TimelineBuilder

  def load_song_for_playback(song_version_id) do
    song_version = SongLibrary.get_song_version_with_timeline!(song_version_id)

    case song_version.music_timeline do
      nil -> {:error, :timeline_not_found}
      timeline -> {:ok, %{song_version: song_version, timeline: timeline}}
    end
  end

  def load_timeline_events(music_timeline_id) do
    TimelineBuilder.build_event_list(music_timeline_id)
  end

  def load_timeline_events_for_version(song_version_id) do
    case load_song_for_playback(song_version_id) do
      {:ok, %{timeline: timeline}} -> TimelineBuilder.build_event_list(timeline.id)
      error -> error
    end
  end
end
