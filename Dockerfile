# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM elixir:1.19.5-otp-28 AS builder

WORKDIR /app

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends build-essential git curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
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
COPY rel rel/

# Install npm dependencies (tone, opensheetmusicdisplay)
RUN npm install --prefix assets

# Compile first — generates the phoenix-colocated/music_learning_platform
# JS module that esbuild needs to resolve the import in app.js
RUN mix compile

# Download esbuild + tailwind binaries and build assets
RUN mix assets.setup
RUN mix assets.deploy

# Build production release (priv/static/ already has digested assets)
RUN MIX_ENV=prod mix do compile + release

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM elixir:1.19.5-otp-28-slim AS runtime

ENV PHX_SERVER=true \
    LANG=en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/music_learning_platform ./

USER nobody

EXPOSE 8080

CMD ["/app/bin/music_learning_platform", "start"]
