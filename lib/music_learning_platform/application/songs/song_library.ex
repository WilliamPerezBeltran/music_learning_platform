defmodule MusicLearningPlatform.Application.Songs.SongLibrary do
  import Ecto.Query

  alias MusicLearningPlatform.Repo
  alias MusicLearningPlatform.Domain.Songs.{Song, SongVersion, ContentAsset}

  def list_published_songs do
    Song
    |> where([s], s.is_published == true)
    |> order_by([s], s.title)
    |> Repo.all()
  end

  def list_songs do
    Song |> order_by([s], s.title) |> Repo.all()
  end

  def get_song!(id), do: Repo.get!(Song, id)

  def get_song_with_versions!(id) do
    Song
    |> Repo.get!(id)
    |> Repo.preload(song_versions: from(sv in SongVersion, order_by: sv.level_index))
  end

  def get_song_version!(id), do: Repo.get!(SongVersion, id)

  def get_song_version_with_timeline!(id) do
    SongVersion
    |> Repo.get!(id)
    |> Repo.preload(:music_timeline)
  end

  def list_song_versions(song_id) do
    SongVersion
    |> where([sv], sv.song_id == ^song_id and sv.is_active == true)
    |> order_by([sv], sv.level_index)
    |> Repo.all()
  end

  def create_song(attrs) do
    %Song{}
    |> Song.changeset(attrs)
    |> Repo.insert()
  end

  def update_song(%Song{} = song, attrs) do
    song
    |> Song.changeset(attrs)
    |> Repo.update()
  end

  def create_song_version(attrs) do
    %SongVersion{}
    |> SongVersion.changeset(attrs)
    |> Repo.insert()
  end

  def create_content_asset(attrs) do
    %ContentAsset{}
    |> ContentAsset.changeset(attrs)
    |> Repo.insert()
  end

  def get_content_asset_by_type(song_id, asset_type) do
    ContentAsset
    |> where([ca], ca.song_id == ^song_id and ca.asset_type == ^asset_type)
    |> Repo.one()
  end
end
