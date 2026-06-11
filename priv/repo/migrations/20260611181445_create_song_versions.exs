defmodule MusicLearningPlatform.Repo.Migrations.CreateSongVersions do
  use Ecto.Migration

  def change do
    create table(:song_versions) do
      add :song_id, references(:songs, on_delete: :delete_all), null: false
      add :version_type, :string, null: false
      add :level_index, :integer, null: false
      add :name, :string, null: false
      add :description, :text
      add :musicxml_path, :string, null: false
      add :difficulty_score, :integer, default: 0
      add :hand_config, :map, default: %{}
      add :visibility_config, :map, default: %{}
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create index(:song_versions, [:song_id])
    create index(:song_versions, [:song_id, :level_index])
    create unique_index(:song_versions, [:song_id, :version_type])
  end
end
