import Config

config :docspec_api,
  env: config_env(),
  start: Mix.env() != :test,
  version: Mix.Project.config()[:version]

config :logger, :console,
  metadata: [
    :crash_reason,
    :"config.docspec_api",
    :conn,
    :error,
    :"service.name",
    :"service.version",
    :"service.environment",
    :"trace.id"
  ]
