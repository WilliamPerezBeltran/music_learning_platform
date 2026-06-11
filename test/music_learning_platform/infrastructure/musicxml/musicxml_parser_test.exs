defmodule MusicLearningPlatform.Infrastructure.MusicXML.MusicXMLParserTest do
  use ExUnit.Case, async: true

  alias MusicLearningPlatform.Infrastructure.MusicXML.MusicXMLParser

  defp simple_xml(bpm, notes) do
    note_elements =
      Enum.map(notes, fn {step, octave, duration} ->
        """
        <note>
          <pitch><step>#{step}</step><octave>#{octave}</octave></pitch>
          <duration>#{duration}</duration>
          <voice>1</voice>
          <type>quarter</type>
        </note>
        """
      end)
      |> Enum.join()

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <score-partwise version="3.1">
      <part-list><score-part id="P1"><part-name>Melody</part-name></score-part></part-list>
      <part id="P1">
        <measure number="1">
          <attributes>
            <divisions>2</divisions>
            <key><fifths>0</fifths></key>
            <time><beats>4</beats><beat-type>4</beat-type></time>
          </attributes>
          <direction><direction-type></direction-type><sound tempo="#{bpm}"/></direction>
          #{note_elements}
        </measure>
      </part>
    </score-partwise>
    """
  end

  defp rest_xml do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <score-partwise version="3.1">
      <part-list><score-part id="P1"><part-name>Melody</part-name></score-part></part-list>
      <part id="P1">
        <measure number="1">
          <attributes><divisions>2</divisions></attributes>
          <direction><direction-type></direction-type><sound tempo="120"/></direction>
          <note><pitch><step>C</step><octave>4</octave></pitch><duration>2</duration><voice>1</voice></note>
          <note><rest/><duration>2</duration><voice>1</voice></note>
          <note><pitch><step>E</step><octave>4</octave></pitch><duration>2</duration><voice>1</voice></note>
        </measure>
      </part>
    </score-partwise>
    """
  end

  describe "parse/1" do
    test "returns ok tuple with bpm and notes" do
      xml = simple_xml(120, [{"C", 4, 2}, {"D", 4, 2}])
      assert {:ok, %{bpm: 120.0, notes: notes}} = MusicXMLParser.parse(xml)
      assert length(notes) == 2
    end

    test "extracts correct pitch" do
      xml = simple_xml(120, [{"G", 4, 2}])
      {:ok, %{notes: [note]}} = MusicXMLParser.parse(xml)
      assert note.pitch == "G4"
    end

    test "calculates start_time and end_time correctly" do
      xml = simple_xml(120, [{"C", 4, 2}, {"D", 4, 2}])
      {:ok, %{notes: [first, second]}} = MusicXMLParser.parse(xml)

      assert_in_delta first.start_time, 0.0, 0.001
      assert_in_delta first.end_time, 0.5, 0.001
      assert_in_delta second.start_time, 0.5, 0.001
      assert_in_delta second.end_time, 1.0, 0.001
    end

    test "assigns sequential index" do
      xml = simple_xml(120, [{"C", 4, 2}, {"D", 4, 2}, {"E", 4, 2}])
      {:ok, %{notes: notes}} = MusicXMLParser.parse(xml)
      assert Enum.map(notes, & &1.index) == [0, 1, 2]
    end

    test "skips rests and advances time" do
      {:ok, %{notes: notes}} = MusicXMLParser.parse(rest_xml())
      assert length(notes) == 2
      [first, second] = notes
      assert first.pitch == "C4"
      assert second.pitch == "E4"
      assert_in_delta second.start_time, 1.0, 0.001
    end

    test "uses 120 bpm as default when no tempo found" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <score-partwise version="3.1">
        <part-list><score-part id="P1"><part-name>M</part-name></score-part></part-list>
        <part id="P1">
          <measure number="1">
            <attributes><divisions>2</divisions></attributes>
            <note><pitch><step>C</step><octave>4</octave></pitch><duration>2</duration><voice>1</voice></note>
          </measure>
        </part>
      </score-partwise>
      """

      {:ok, %{bpm: bpm}} = MusicXMLParser.parse(xml)
      assert bpm == 120.0
    end

    test "voice 1 maps to right_hand" do
      xml = simple_xml(120, [{"C", 4, 2}])
      {:ok, %{notes: [note]}} = MusicXMLParser.parse(xml)
      assert note.voice == "right_hand"
    end

    test "returns error on invalid xml" do
      assert {:error, _reason} = MusicXMLParser.parse("not xml at all <<<")
    end

    test "parses real bartolito file" do
      path =
        Path.join([
          Application.app_dir(:music_learning_platform, "priv"),
          "static",
          "songs",
          "bartolito_level1.xml"
        ])

      xml = File.read!(path)
      assert {:ok, %{bpm: 120.0, notes: notes}} = MusicXMLParser.parse(xml)
      assert length(notes) > 0
    end
  end
end
