defmodule MusicLearningPlatform.Infrastructure.Workers.PreprocessingWorker do
  alias MusicLearningPlatform.Application.Songs.SongLibrary
  alias MusicLearningPlatform.Infrastructure.Workers.MusicXMLWorker

  def preprocess_song(song_id) do
    song_id
    |> SongLibrary.list_song_versions()
    |> Enum.map(fn version ->
      Task.async_stream(
        [version],
        fn sv -> MusicXMLWorker.process(sv.id, sv.musicxml_path) end,
        timeout: :infinity
      )
      |> Enum.to_list()
    end)
  end
end
