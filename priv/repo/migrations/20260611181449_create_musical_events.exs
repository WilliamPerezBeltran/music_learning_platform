defmodule MusicLearningPlatform.Repo.Migrations.CreateMusicalEvents do
  use Ecto.Migration

  def change do
    create table(:musical_events) do
      add :music_timeline_id, references(:music_timelines, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :pitch, :string
      add :start_time, :float, null: false
      add :end_time, :float, null: false
      add :duration, :float, null: false
      add :velocity, :integer
      add :voice, :string, null: false
      add :color_key, :string
      add :index, :integer, null: false
      add :metadata, :map
    end

    create index(:musical_events, [:music_timeline_id])
    create index(:musical_events, [:music_timeline_id, :start_time])
    create index(:musical_events, [:music_timeline_id, :index])
  end
end
