defmodule MusicLearningPlatform.Domain.Songs.Song do
  use Ecto.Schema
  import Ecto.Changeset

  alias MusicLearningPlatform.Domain.Songs.{SongVersion, ContentAsset}

  schema "songs" do
    field :title, :string
    field :artist, :string
    field :category, :string
    field :description, :string
    field :duration_seconds, :float
    field :thumbnail_url, :string
    field :is_published, :boolean, default: false
    field :metadata, :map

    has_many :song_versions, SongVersion
    has_many :content_assets, ContentAsset

    timestamps()
  end

  @required [:title, :category]
  @optional [:artist, :description, :duration_seconds, :thumbnail_url, :is_published, :metadata]

  def changeset(song, attrs) do
    song
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:title, min: 1, max: 255)
  end
end
