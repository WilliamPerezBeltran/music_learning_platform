defmodule MusicLearningPlatform.Repo.Migrations.CreateMusicTimelines do
  use Ecto.Migration

  def change do
    create table(:music_timelines) do
      add :song_version_id, references(:song_versions, on_delete: :delete_all), null: false
      add :bpm, :float, null: false
      add :total_duration, :float, null: false
      add :resolution, :integer, default: 480
      add :source_format, :string, null: false, default: "musicxml"

      timestamps()
    end

    create unique_index(:music_timelines, [:song_version_id])
  end
end
