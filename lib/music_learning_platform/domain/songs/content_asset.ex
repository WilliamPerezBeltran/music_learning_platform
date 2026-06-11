defmodule MusicLearningPlatform.Domain.Songs.ContentAsset do
  use Ecto.Schema
  import Ecto.Changeset

  alias MusicLearningPlatform.Domain.Songs.Song

  @asset_types ~w(musicxml audio image midi)

  schema "content_assets" do
    field :asset_type, :string
    field :file_path, :string
    field :version, :string
    field :checksum, :string
    field :uploaded_by, :string

    belongs_to :song, Song

    timestamps()
  end

  @required [:song_id, :asset_type, :file_path]
  @optional [:version, :checksum, :uploaded_by]

  def changeset(asset, attrs) do
    asset
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:asset_type, @asset_types)
    |> foreign_key_constraint(:song_id)
  end
end
