defmodule MusicLearningPlatform.Domain.Timeline.MusicalEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias MusicLearningPlatform.Domain.Timeline.MusicTimeline

  @event_types ~w(note_on note_off chord rest)
  @voices ~w(melody left_hand right_hand)

  schema "musical_events" do
    field :event_type, :string
    field :pitch, :string
    field :start_time, :float
    field :end_time, :float
    field :duration, :float
    field :velocity, :integer
    field :voice, :string
    field :color_key, :string
    field :index, :integer
    field :metadata, :map

    belongs_to :music_timeline, MusicTimeline
  end

  @required [:music_timeline_id, :event_type, :start_time, :end_time, :duration, :voice, :index]
  @optional [:pitch, :velocity, :color_key, :metadata]

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:event_type, @event_types)
    |> validate_inclusion(:voice, @voices)
    |> validate_number(:start_time, greater_than_or_equal_to: 0)
    |> validate_number(:end_time, greater_than: 0)
    |> validate_number(:duration, greater_than: 0)
    |> foreign_key_constraint(:music_timeline_id)
  end
end
