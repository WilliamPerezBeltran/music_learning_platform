alias MusicLearningPlatform.Repo
alias MusicLearningPlatform.Domain.Songs.{Song, SongVersion, ContentAsset}
alias MusicLearningPlatform.Infrastructure.Workers.MusicXMLWorker

songs = [
  %{
    title: "Bartolito",
    artist: "Tradicional",
    category: "infantil",
    description: "Canción infantil colombiana",
    duration_seconds: 24.0,
    is_published: true,
    versions: [
      %{
        version_type: "melody",
        level_index: 1,
        name: "Solo melodía",
        musicxml_path: "bartolito_level1.xml",
        difficulty_score: 20
      }
    ]
  },
  %{
    title: "Estrellita",
    artist: "Tradicional",
    category: "infantil",
    description: "Brilla brilla la estrellita",
    duration_seconds: 32.0,
    is_published: true,
    versions: [
      %{
        version_type: "melody",
        level_index: 1,
        name: "Solo melodía",
        musicxml_path: "estrellita_level1.xml",
        difficulty_score: 15
      }
    ]
  }
]

Enum.each(songs, fn song_data ->
  {versions_data, song_attrs} = Map.pop(song_data, :versions)

  song =
    case Repo.get_by(Song, title: song_attrs.title) do
      nil ->
        %Song{} |> Song.changeset(song_attrs) |> Repo.insert!()

      existing ->
        existing
    end

  unless Repo.get_by(ContentAsset, song_id: song.id, asset_type: "musicxml") do
    %ContentAsset{}
    |> ContentAsset.changeset(%{
      song_id: song.id,
      asset_type: "musicxml",
      file_path: List.first(versions_data).musicxml_path
    })
    |> Repo.insert!()
  end

  Enum.each(versions_data, fn version_attrs ->
    version =
      case Repo.get_by(SongVersion, song_id: song.id, version_type: version_attrs.version_type) do
        nil ->
          %SongVersion{}
          |> SongVersion.changeset(Map.put(version_attrs, :song_id, song.id))
          |> Repo.insert!()

        existing ->
          existing
      end

    case MusicXMLWorker.process(version.id, version.musicxml_path) do
      {:ok, _result} ->
        IO.puts("  ✓ #{song.title} — #{version.name} procesado")

      {:error, reason} ->
        IO.puts("  ✗ #{song.title} — #{version.name} error: #{inspect(reason)}")
    end
  end)
end)

IO.puts("\nSeed completado.")
