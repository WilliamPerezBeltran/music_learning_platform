defmodule MusicLearningPlatform.Domain.Timeline.MusicTimeline do
  use Ecto.Schema
  import Ecto.Changeset

  alias MusicLearningPlatform.Domain.Songs.SongVersion
  alias MusicLearningPlatform.Domain.Timeline.MusicalEvent

  @source_formats ~w(musicxml midi manual)

  schema "music_timelines" do
    field :bpm, :float
    field :total_duration, :float
    field :resolution, :integer, default: 480
    field :source_format, :string, default: "musicxml"

    belongs_to :song_version, SongVersion
    has_many :musical_events, MusicalEvent

    timestamps()
  end

  @required [:song_version_id, :bpm, :total_duration]
  @optional [:resolution, :source_format]

  def changeset(timeline, attrs) do
    timeline
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_number(:bpm, greater_than: 0)
    |> validate_number(:total_duration, greater_than: 0)
    |> validate_inclusion(:source_format, @source_formats)
    |> foreign_key_constraint(:song_version_id)
    |> unique_constraint(:song_version_id)
  end
end
