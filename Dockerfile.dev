FROM elixir:1.19.5

WORKDIR /app

RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  inotify-tools \
  && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . .

RUN mix compile

EXPOSE 4000

CMD ["mix", "phx.server"]
