defmodule MusicLearningPlatform.Infrastructure.Storage.FileStorage do
  @priv_path "priv/static/songs"

  def read(path) do
    full_path = resolve_path(path)

    case File.read(full_path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end

  def write(path, content) do
    full_path = resolve_path(path)
    dir = Path.dirname(full_path)
    File.mkdir_p!(dir)
    File.write(full_path, content)
  end

  def exists?(path) do
    path |> resolve_path() |> File.exists?()
  end

  def list(subdir \\ "") do
    base = resolve_path(subdir)

    case File.ls(base) do
      {:ok, files} -> {:ok, files}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_path("/" <> _ = absolute_path), do: absolute_path
  defp resolve_path(relative_path), do: Path.join([@priv_path, relative_path])
end
