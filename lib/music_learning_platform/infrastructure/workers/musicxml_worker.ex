defmodule MusicLearningPlatform.Infrastructure.Workers.MusicXMLWorker do
  alias MusicLearningPlatform.Infrastructure.MusicXML.{MusicXMLParser, TimelineBuilder}
  alias MusicLearningPlatform.Infrastructure.Storage.FileStorage

  def process(song_version_id, musicxml_path) do
    with {:ok, xml_content} <- FileStorage.read(musicxml_path),
         {:ok, parsed} <- MusicXMLParser.parse(xml_content),
         {:ok, result} <- TimelineBuilder.build_from_parsed(song_version_id, parsed) do
      {:ok, result}
    end
  end
end
