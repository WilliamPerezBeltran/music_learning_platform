defmodule MusicLearningPlatform.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs) do
      add :title, :string, null: false
      add :artist, :string
      add :category, :string, null: false
      add :description, :text
      add :duration_seconds, :float
      add :thumbnail_url, :string
      add :is_published, :boolean, default: false, null: false
      add :metadata, :map

      timestamps()
    end

    create index(:songs, [:category])
    create index(:songs, [:is_published])
  end
end
