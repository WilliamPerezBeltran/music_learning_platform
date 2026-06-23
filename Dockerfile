# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM elixir:1.19.5-otp-28 AS builder

WORKDIR /app

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends build-essential git && \
    rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

# Cache deps layer
COPY mix.exs mix.lock ./
# Fetch ALL deps (dev included) — esbuild + tailwind are dev-only deps
RUN mix deps.get

COPY config config/
COPY priv priv/
COPY assets assets/
COPY lib lib/

# Download esbuild + tailwind binaries and compile assets
RUN mix assets.setup
RUN mix assets.deploy

# Build production release (priv/static/ already has digested assets)
RUN MIX_ENV=prod mix do compile, release

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS runtime

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      libstdc++6 openssl libncurses5 locales ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV PHX_SERVER=true

WORKDIR /app
RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/music_learning_platform ./

USER nobody

EXPOSE 4000

CMD ["/app/bin/music_learning_platform", "start"]
