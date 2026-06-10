defmodule MusicLearningPlatform.Repo do
  use Ecto.Repo,
    otp_app: :music_learning_platform,
    adapter: Ecto.Adapters.Postgres
end
