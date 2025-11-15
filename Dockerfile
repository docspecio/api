FROM elixir:1.18-alpine AS build
WORKDIR /usr/src/app

ENV MIX_ENV=prod

RUN apk add --no-cache git
RUN mix local.hex --force && mix local.rebar --force

COPY . .

RUN mix deps.get && mix release

FROM elixir:1.18-alpine

ENV MIX_ENV=prod

COPY --from=build /usr/src/app /usr/src/app

EXPOSE 4000

WORKDIR /usr/src/app

CMD ["_build/prod/rel/docspec_api/bin/docspec_api", "start"]
