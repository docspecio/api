import Config

config :docspec,
  env: config_env(),
  start: Mix.env() != :test,
  version: Mix.Project.config()[:version]

config :logger, :console,
  metadata: [
    :crash_reason,
    :"config.docspec",
    :conn,
    :error,
    :"service.name",
    :"service.version",
    :"service.environment",
    :"trace.id"
  ]
