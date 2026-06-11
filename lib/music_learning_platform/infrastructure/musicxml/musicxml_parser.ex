defmodule MusicLearningPlatform.Infrastructure.MusicXML.MusicXMLParser do
  import SweetXml

  def parse(xml_string) do
    doc = SweetXml.parse(xml_string)

    bpm = extract_bpm(doc)
    notes = extract_notes(doc, bpm)

    {:ok, %{bpm: bpm, notes: notes}}
  rescue
    e -> {:error, Exception.message(e)}
  catch
    :exit, reason -> {:error, inspect(reason)}
  end

  defp extract_bpm(doc) do
    case xpath(doc, ~x"//sound/@tempo"o) do
      nil -> 120.0
      val -> val |> to_string() |> Float.parse() |> elem(0)
    end
  end

  defp extract_notes(doc, bpm) do
    quarter_seconds = 60.0 / bpm
    measures = xpath(doc, ~x"//measure"l)

    {notes, _time, _divisions} =
      Enum.reduce(measures, {[], 0.0, 1}, fn measure, {acc, current_time, prev_divisions} ->
        divisions =
          case xpath(measure, ~x"./attributes/divisions/text()"oi) do
            0 -> prev_divisions
            nil -> prev_divisions
            val -> val
          end

        raw_notes =
          xpath(measure, ~x"./note"l,
            step: ~x"./pitch/step/text()"os,
            octave: ~x"./pitch/octave/text()"os,
            duration: ~x"./duration/text()"oi,
            voice: ~x"./voice/text()"oi,
            rest: ~x"./rest"o,
            chord: ~x"./chord"o
          )

        {measure_notes, new_time} =
          Enum.reduce(raw_notes, {[], current_time}, fn note, {events, time} ->
            dur_seconds = note.duration / divisions * quarter_seconds

            # chord element means this note starts at the same time as the previous
            start_time =
              if note.chord != nil,
                do: time - (List.last(events) || %{duration: 0.0}).duration,
                else: time

            if note.rest != nil do
              {events, time + dur_seconds}
            else
              event = %{
                pitch: "#{note.step}#{note.octave}",
                start_time: start_time,
                end_time: start_time + dur_seconds,
                duration: dur_seconds,
                voice: voice_label(note.voice)
              }

              advance = if note.chord != nil, do: 0.0, else: dur_seconds
              {events ++ [event], time + advance}
            end
          end)

        {acc ++ measure_notes, new_time, divisions}
      end)

    Enum.with_index(notes, fn note, idx -> Map.put(note, :index, idx) end)
  end

  defp voice_label(1), do: "right_hand"
  defp voice_label(2), do: "left_hand"
  defp voice_label(_), do: "melody"
end
