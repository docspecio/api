defmodule DocSpec.Application do
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    env = Application.get_env(:docspec_api, :env)
    version = Application.get_env(:docspec_api, :version)
    port = Application.get_env(:docspec_api, :port)

    Application.ensure_all_started(:logger_json)

    initialize_logging("docspec_api", version, env)

    Logger.info("Starting DocSpec API server v#{version} (env: #{env})")

    children = [
      {Bandit, plug: DocSpec.API, port: port, scheme: :http}
    ]

    LoggerJSON.Plug.attach("logger-json-requests", [:docspec_api, :plug, :stop], :info)

    opts = [strategy: :one_for_one, name: DocSpec.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec initialize_logging(name :: String.t(), version :: String.t(), env :: String.t()) :: :ok
  defp initialize_logging(name, version, env) do
    metadata =
      ["service.name": name, "service.version": version, "service.environment": env]
      |> Enum.into(:logger.get_primary_config().metadata)

    :logger.set_primary_config(:metadata, metadata)
  end
end
