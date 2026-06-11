defmodule MusicLearningPlatform.Infrastructure.Storage.FileStorageTest do
  use ExUnit.Case, async: true

  alias MusicLearningPlatform.Infrastructure.Storage.FileStorage

  describe "read/1" do
    test "reads an existing file" do
      assert {:ok, content} = FileStorage.read("bartolito_level1.xml")
      assert String.contains?(content, "Bartolito")
    end

    test "returns error for missing file" do
      assert {:error, _reason} = FileStorage.read("nonexistent.xml")
    end
  end

  describe "exists?/1" do
    test "returns true for existing file" do
      assert FileStorage.exists?("bartolito_level1.xml")
    end

    test "returns false for missing file" do
      refute FileStorage.exists?("ghost.xml")
    end
  end

  describe "list/0" do
    test "returns list of files in songs directory" do
      {:ok, files} = FileStorage.list()
      assert "bartolito_level1.xml" in files
      assert "estrellita_level1.xml" in files
    end
  end
end
