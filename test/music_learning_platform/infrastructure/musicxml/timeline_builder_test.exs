defmodule MusicLearningPlatform.Infrastructure.MusicXML.TimelineBuilderTest do
  use MusicLearningPlatform.DataCase, async: true

  alias MusicLearningPlatform.Domain.Songs.{Song, SongVersion}
  alias MusicLearningPlatform.Infrastructure.MusicXML.TimelineBuilder

  defp insert_version do
    song = %Song{} |> Song.changeset(%{title: "Test", category: "test"}) |> Repo.insert!()

    %SongVersion{}
    |> SongVersion.changeset(%{
      song_id: song.id,
      version_type: "melody",
      level_index: 1,
      name: "Test",
      musicxml_path: "test.xml"
    })
    |> Repo.insert!()
  end

  defp parsed_data do
    %{
      bpm: 120.0,
      notes: [
        %{index: 0, pitch: "C4", start_time: 0.0, end_time: 0.5, duration: 0.5, voice: "melody"},
        %{index: 1, pitch: "D4", start_time: 0.5, end_time: 1.0, duration: 0.5, voice: "melody"},
        %{index: 2, pitch: "E4", start_time: 1.0, end_time: 1.5, duration: 0.5, voice: "melody"}
      ]
    }
  end

  describe "build_from_parsed/2" do
    test "creates timeline and events in a transaction" do
      version = insert_version()

      assert {:ok, %{timeline: timeline, events: events}} =
               TimelineBuilder.build_from_parsed(version.id, parsed_data())

      assert timeline.bpm == 120.0
      assert timeline.song_version_id == version.id
      assert length(events) == 3
    end

    test "sets total_duration from last note end_time" do
      version = insert_version()
      {:ok, %{timeline: timeline}} = TimelineBuilder.build_from_parsed(version.id, parsed_data())
      assert_in_delta timeline.total_duration, 1.5, 0.001
    end

    test "assigns color_key to events" do
      version = insert_version()
      {:ok, %{events: events}} = TimelineBuilder.build_from_parsed(version.id, parsed_data())
      c_event = Enum.find(events, &(&1.pitch == "C4"))
      assert c_event.color_key == "do"
    end
  end

  describe "build_event_list/1" do
    test "returns events ordered by index" do
      version = insert_version()
      {:ok, %{timeline: timeline}} = TimelineBuilder.build_from_parsed(version.id, parsed_data())

      {:ok, events} = TimelineBuilder.build_event_list(timeline.id)
      assert Enum.map(events, & &1.index) == [0, 1, 2]
    end

    test "returns error when timeline not found" do
      {:ok, events} = TimelineBuilder.build_event_list(999_999)
      assert events == []
    end
  end
end
