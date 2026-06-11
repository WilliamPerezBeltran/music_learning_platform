defmodule MusicLearningPlatform.Repo.Migrations.CreatePlaybackSessions do
  use Ecto.Migration

  def change do
    create table(:playback_sessions) do
      add :song_id, references(:songs, on_delete: :delete_all), null: false
      add :song_version_id, references(:song_versions, on_delete: :delete_all), null: false
      add :current_time, :float, default: 0.0, null: false
      add :is_playing, :boolean, default: false, null: false
      add :speed, :float, default: 1.0, null: false
      add :loop_enabled, :boolean, default: false, null: false
      add :client_id, :string
      add :started_at, :utc_datetime
      add :paused_at, :utc_datetime

      timestamps()
    end

    create index(:playback_sessions, [:song_id])
    create index(:playback_sessions, [:client_id])
  end
end
