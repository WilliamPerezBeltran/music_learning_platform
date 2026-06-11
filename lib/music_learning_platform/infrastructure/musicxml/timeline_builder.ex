defmodule MusicLearningPlatform.Infrastructure.MusicXML.TimelineBuilder do
  import Ecto.Query

  alias MusicLearningPlatform.Repo
  alias MusicLearningPlatform.Domain.Timeline.{MusicTimeline, MusicalEvent}
  alias MusicLearningPlatform.Application.Visual.ColorMapper

  def build_from_parsed(song_version_id, %{bpm: bpm, notes: notes}) do
    total_duration =
      notes
      |> Enum.map(& &1.end_time)
      |> Enum.max(fn -> 0.0 end)

    Repo.transaction(fn ->
      {:ok, timeline} =
        %MusicTimeline{}
        |> MusicTimeline.changeset(%{
          song_version_id: song_version_id,
          bpm: bpm,
          total_duration: total_duration,
          source_format: "musicxml"
        })
        |> Repo.insert()

      events =
        Enum.map(notes, fn note ->
          %{
            music_timeline_id: timeline.id,
            event_type: "note_on",
            pitch: note.pitch,
            start_time: note.start_time,
            end_time: note.end_time,
            duration: note.duration,
            voice: note.voice,
            color_key: ColorMapper.color_for_pitch(note.pitch),
            index: note.index
          }
        end)

      {_count, inserted} = Repo.insert_all(MusicalEvent, events, returning: true)

      %{timeline: timeline, events: inserted}
    end)
  end

  def build_event_list(music_timeline_id) do
    events =
      MusicalEvent
      |> where([e], e.music_timeline_id == ^music_timeline_id)
      |> order_by([e], e.index)
      |> Repo.all()

    {:ok, events}
  end
end
