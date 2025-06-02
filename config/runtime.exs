import Config

Code.ensure_loaded!(LoggerJSON.Formatters.Elastic)

config :logger, :default_handler, formatter: LoggerJSON.Formatters.Elastic.new(metadata: :all)

config :docspec,
  port: System.get_env("PORT", "4000")

config :logger, :default_handler, formatter: LoggerJSON.Formatters.Elastic.new(metadata: :all)

ca_certificates_path = System.get_env("CA_CERTIFICATES_PATH")
