# DocSpec Import API

This repository contains an Elixir application that exposes a small HTTP API for converting DOCX documents into [BlockNote](https://blocknotejs.org/) JSON.  It also provides a companion Node based service that converts BlockNote blocks into Y.js updates.

## Project layout

- **Elixir application** – defined in `mix.exs` and built with [Plug](https://hexdocs.pm/plug) and [Bandit](https://hexdocs.pm/bandit). The main router lives in [`lib/docspec/api.ex`](lib/docspec/api.ex) and exposes a `/conversion` endpoint implemented in [`lib/docspec/api/controller/conversion.ex`](lib/docspec/api/controller/conversion.ex).
- **Node service** – located in [`blocknote-api`](blocknote-api/) and implemented in [`src/main.ts`](blocknote-api/src/main.ts). This service listens for JSON blocks on port `9871` (configurable with the `PORT` environment variable) and returns a base64 encoded Y.js update.
- **Docker setup** – `Dockerfile` builds the Elixir release and `docker-compose.yml` wires the services behind Traefik.

## Usage

The easiest way to run everything locally is with Docker:

```bash
docker-compose up --build
```

Alternatively you can build the Elixir release yourself:

```bash
mix deps.get
mix release
_build/prod/rel/docspec/bin/docspec start
```

Once running you can POST a DOCX file to convert:

```bash
curl -X POST http://localhost:4000/conversion -F "file=@path/to/document.docx"
```

The response body is the converted BlockNote JSON.

## Testing

Elixir tests can be run with:

```bash
mix test
```

Node tests (if any) can be executed with:

```bash
npm test --prefix blocknote-api
```

## License

See [`LICENSE`](LICENSE) for license information (EUPL v1.2).
