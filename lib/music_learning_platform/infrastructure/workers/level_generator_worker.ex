defmodule MusicLearningPlatform.Infrastructure.Workers.LevelGeneratorWorker do
  alias MusicLearningPlatform.Application.Songs.SongLibrary

  @levels [
    %{version_type: "melody", level_index: 1, name: "Solo melodía", difficulty_score: 20},
    %{
      version_type: "simplified",
      level_index: 2,
      name: "Melodía simplificada",
      difficulty_score: 35
    },
    %{version_type: "chords", level_index: 3, name: "Melodía + acordes", difficulty_score: 55},
    %{version_type: "full", level_index: 4, name: "Canción completa", difficulty_score: 80}
  ]

  def generate_levels(song_id, base_musicxml_path) do
    Enum.map(@levels, fn level_attrs ->
      attrs =
        Map.merge(level_attrs, %{
          song_id: song_id,
          musicxml_path: base_musicxml_path
        })

      SongLibrary.create_song_version(attrs)
    end)
  end
end
