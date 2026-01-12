FROM elixir:1.19-alpine AS build
WORKDIR /usr/src/app

ENV MIX_ENV=prod

RUN apk add --no-cache git
RUN mix local.hex --force && mix local.rebar --force

COPY . .

RUN mix deps.get && mix release

FROM elixir:1.19-alpine

ENV MIX_ENV=prod

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser

COPY --from=build --chown=appuser:appgroup /usr/src/app /usr/src/app

EXPOSE 4000

WORKDIR /usr/src/app

# Run as non-root user (use numeric UID for Kubernetes runAsNonRoot verification)
USER 1000

CMD ["_build/prod/rel/docspec_api/bin/docspec_api", "start"]
