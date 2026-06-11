defmodule MusicLearningPlatform.Repo.Migrations.CreateContentAssets do
  use Ecto.Migration

  def change do
    create table(:content_assets) do
      add :song_id, references(:songs, on_delete: :delete_all), null: false
      add :asset_type, :string, null: false
      add :file_path, :string, null: false
      add :version, :string
      add :checksum, :string
      add :uploaded_by, :string

      timestamps()
    end

    create index(:content_assets, [:song_id])
    create index(:content_assets, [:song_id, :asset_type])
  end
end
