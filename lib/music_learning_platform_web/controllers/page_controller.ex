defmodule MusicLearningPlatformWeb.PageController do
  use MusicLearningPlatformWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
