defmodule MusicLearningPlatform.Infrastructure.MusicXML.MusicXMLParser do
  import SweetXml

  def parse(xml_string) do
    doc = SweetXml.parse(xml_string)

    bpm = extract_bpm(doc)
    notes = extract_notes(doc, bpm)

    {:ok, %{bpm: bpm, notes: notes}}
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp extract_bpm(doc) do
    doc
    |> xpath(~x"//sound/@tempo"o)
    |> case do
      nil -> 120.0
      val -> val |> to_string() |> Float.parse() |> elem(0)
    end
  end

  defp extract_notes(doc, bpm) do
    quarter_duration_seconds = 60.0 / bpm

    doc
    |> xpath(~x"//note"l,
      pitch: ~x"./pitch/step/text()"os,
      octave: ~x"./pitch/octave/text()"os,
      duration: ~x"./duration/text()"oi,
      divisions: ~x"ancestor::measure/attributes/divisions/text()"oi,
      rest: ~x"./rest"o,
      voice: ~x"./voice/text()"oi
    )
    |> Enum.reject(&(&1.rest != nil))
    |> Enum.with_index()
    |> Enum.map_reduce(0.0, fn {note, idx}, current_time ->
      divisions = if note.divisions > 0, do: note.divisions, else: 1
      duration_seconds = note.duration / divisions * quarter_duration_seconds

      event = %{
        index: idx,
        pitch: "#{note.pitch}#{note.octave}",
        start_time: current_time,
        end_time: current_time + duration_seconds,
        duration: duration_seconds,
        voice: voice_label(note.voice)
      }

      {event, current_time + duration_seconds}
    end)
    |> elem(0)
  end

  defp voice_label(1), do: "right_hand"
  defp voice_label(2), do: "left_hand"
  defp voice_label(_), do: "melody"
end
