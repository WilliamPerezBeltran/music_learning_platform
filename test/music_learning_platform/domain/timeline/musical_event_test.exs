defmodule MusicLearningPlatform.Domain.Timeline.MusicalEventTest do
  use MusicLearningPlatform.DataCase, async: true

  alias MusicLearningPlatform.Domain.Songs.{Song, SongVersion}
  alias MusicLearningPlatform.Domain.Timeline.{MusicTimeline, MusicalEvent}

  defp insert_timeline do
    song = %Song{} |> Song.changeset(%{title: "Test", category: "test"}) |> Repo.insert!()

    version =
      %SongVersion{}
      |> SongVersion.changeset(%{
        song_id: song.id,
        version_type: "melody",
        level_index: 1,
        name: "Test",
        musicxml_path: "test.xml"
      })
      |> Repo.insert!()

    %MusicTimeline{}
    |> MusicTimeline.changeset(%{
      song_version_id: version.id,
      bpm: 120.0,
      total_duration: 10.0
    })
    |> Repo.insert!()
  end

  describe "changeset/2" do
    test "valid with required fields" do
      timeline = insert_timeline()

      attrs = %{
        music_timeline_id: timeline.id,
        event_type: "note_on",
        start_time: 0.0,
        end_time: 0.5,
        duration: 0.5,
        voice: "melody",
        index: 0
      }

      assert MusicalEvent.changeset(%MusicalEvent{}, attrs).valid?
    end

    test "invalid with unknown event_type" do
      timeline = insert_timeline()

      attrs = %{
        music_timeline_id: timeline.id,
        event_type: "unknown",
        start_time: 0.0,
        end_time: 0.5,
        duration: 0.5,
        voice: "melody",
        index: 0
      }

      changeset = MusicalEvent.changeset(%MusicalEvent{}, attrs)
      refute changeset.valid?
      assert %{event_type: ["is invalid"]} = errors_on(changeset)
    end

    test "invalid with unknown voice" do
      timeline = insert_timeline()

      attrs = %{
        music_timeline_id: timeline.id,
        event_type: "note_on",
        start_time: 0.0,
        end_time: 0.5,
        duration: 0.5,
        voice: "unknown",
        index: 0
      }

      changeset = MusicalEvent.changeset(%MusicalEvent{}, attrs)
      refute changeset.valid?
      assert %{voice: ["is invalid"]} = errors_on(changeset)
    end

    test "invalid with negative duration" do
      timeline = insert_timeline()

      attrs = %{
        music_timeline_id: timeline.id,
        event_type: "note_on",
        start_time: 0.0,
        end_time: 0.5,
        duration: -0.5,
        voice: "melody",
        index: 0
      }

      changeset = MusicalEvent.changeset(%MusicalEvent{}, attrs)
      refute changeset.valid?
    end
  end
end
