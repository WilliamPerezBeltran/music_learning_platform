defmodule MusicLearningPlatform.Domain.Playback.PlaybackSession do
  use Ecto.Schema
  import Ecto.Changeset

  alias MusicLearningPlatform.Domain.Songs.{Song, SongVersion}

  schema "playback_sessions" do
    field :current_time, :float, default: 0.0
    field :is_playing, :boolean, default: false
    field :speed, :float, default: 1.0
    field :loop_enabled, :boolean, default: false
    field :client_id, :string
    field :started_at, :utc_datetime
    field :paused_at, :utc_datetime

    belongs_to :song, Song
    belongs_to :song_version, SongVersion

    timestamps()
  end

  @required [:song_id, :song_version_id]
  @optional [
    :current_time,
    :is_playing,
    :speed,
    :loop_enabled,
    :client_id,
    :started_at,
    :paused_at
  ]

  def changeset(session, attrs) do
    session
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_number(:speed, greater_than_or_equal_to: 0.5, less_than_or_equal_to: 2.0)
    |> validate_number(:current_time, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:song_id)
    |> foreign_key_constraint(:song_version_id)
  end
end
