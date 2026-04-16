defmodule DocSpec.API do
  @moduledoc """
  Plug for the API.
  """

  require Logger

  alias DocSpec.API.Controller
  alias DocSpec.API.Plug.ProblemDetails

  use Plug.Router
  use DocSpec.API.Plug.ErrorHandler

  plug :match
  plug DocSpec.API.Plug.Tracing, header: "x-request-id", key: "http.request.id"
  plug DocSpec.API.Plug.Tracing, header: "x-trace-id", key: "trace.id"
  plug DocSpec.API.Plug.PutRespHeader, key: "access-control-allow-origin", value: "*"
  plug Plug.Telemetry, event_prefix: [:docspec_api, :plug]
  plug :dispatch

  match "/conversion", to: Controller.Conversion
  match "/health", to: Controller.Health

  match _ do
    ProblemDetails.send(conn, 404, "Not Found", "The requested resource does not exist.")
  end

  @impl DocSpec.API.Plug.ErrorHandler
  def handle_errors(conn, _, %Plug.Parsers.RequestTooLargeError{}, _) do
    ProblemDetails.payload_too_large(conn, "Request body exceeds maximum size")
  end

  def handle_errors(conn, _, error = %Plug.Parsers.UnsupportedMediaTypeError{}, _) do
    ProblemDetails.unsupported_media_type(conn, unsupported_media_type_detail(error.media_type))
  end

  def handle_errors(conn, _kind, reason, stack) do
    Logger.error("Unexpected error: #{inspect(reason)}",
      conn: conn,
      crash_reason: {reason, stack}
    )

    ProblemDetails.internal_server_error(
      conn,
      "An unexpected error occurred during conversion"
    )
  end

  defp unsupported_media_type_detail("multipart/" <> _) do
    "Multipart uploads are not supported. Send raw binary body."
  end

  defp unsupported_media_type_detail(media_type) when is_binary(media_type) do
    "Unsupported media type: #{media_type}."
  end

  defp unsupported_media_type_detail(_) do
    "Unsupported media type."
  end
end
