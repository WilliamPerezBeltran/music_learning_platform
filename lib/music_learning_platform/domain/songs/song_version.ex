defmodule MusicLearningPlatform.Domain.Songs.SongVersion do
  use Ecto.Schema
  import Ecto.Changeset

  alias MusicLearningPlatform.Domain.Songs.Song
  alias MusicLearningPlatform.Domain.Timeline.MusicTimeline

  @version_types ~w(melody simplified chords full custom)

  schema "song_versions" do
    field :version_type, :string
    field :level_index, :integer
    field :name, :string
    field :description, :string
    field :musicxml_path, :string
    field :difficulty_score, :integer, default: 0
    field :hand_config, :map, default: %{}
    field :visibility_config, :map, default: %{}
    field :is_active, :boolean, default: true

    belongs_to :song, Song
    has_one :music_timeline, MusicTimeline

    timestamps()
  end

  @required [:song_id, :version_type, :level_index, :name, :musicxml_path]
  @optional [:description, :difficulty_score, :hand_config, :visibility_config, :is_active]

  def changeset(song_version, attrs) do
    song_version
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:version_type, @version_types)
    |> validate_number(:level_index, greater_than_or_equal_to: 1)
    |> validate_number(:difficulty_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> foreign_key_constraint(:song_id)
    |> unique_constraint([:song_id, :version_type])
  end
end
