FROM elixir:1.19-alpine AS build
WORKDIR /usr/src/app

ENV MIX_ENV=prod

RUN apk add --no-cache git
RUN mix local.hex --force && mix local.rebar --force

COPY . .

RUN mix deps.get && mix release

FROM elixir:1.19-alpine

ENV MIX_ENV=prod

RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -s /bin/sh -D appuser

WORKDIR /usr/src/app

COPY --from=build --chown=appuser:appgroup /usr/src/app /usr/src/app

EXPOSE 4000

USER appuser

CMD ["_build/prod/rel/docspec_api/bin/docspec_api", "start"]
