defmodule MusicLearningPlatform.Release do
  @app :music_learning_platform

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()
    seed_path = Application.app_dir(@app, "priv/repo/seeds.exs")

    for repo <- repos() do
      Ecto.Migrator.with_repo(repo, fn _repo ->
        Code.eval_file(seed_path)
      end)
    end
  end

  defp repos, do: Application.fetch_env!(@app, :ecto_repos)

  defp load_app, do: Application.load(@app)
end
