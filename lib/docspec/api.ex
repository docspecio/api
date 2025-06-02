defmodule DocSpec.API do
  @moduledoc """
  Plug for the API.
  """

  @not_found_text """
  Hey! Welcome to my API.

  To test this API, just curl a DOCX Document to me!

  You can do this, for example by using the following command:

      curl -X POST https://api.docspec.dev/conversion -F "file=@<path on your filesystem to your docx>"

  Let me know what you think! Bye!
  """

  require Logger

  alias DocSpec.API.Controller
  alias DocSpec.API.Respond

  use Plug.Router
  use DocSpec.API.Plug.ErrorHandler

  plug :match
  plug DocSpec.API.Plug.Tracing, header: "x-request-id", key: "http.request.id"
  plug DocSpec.API.Plug.Tracing, header: "x-trace-id", key: "trace.id"
  plug DocSpec.API.Plug.PutRespHeader, key: "access-control-allow-origin", value: "*"
  plug Plug.Telemetry, event_prefix: [:docspec, :plug]
  plug :dispatch

  match "/conversion", to: Controller.Conversion

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> Respond.respond(404, @not_found_text)
  end

  @impl DocSpec.API.Plug.ErrorHandler
  def handle_errors(conn, _, %Plug.Parsers.UnsupportedMediaTypeError{media_type: media_type}, _) do
    conn |> Respond.error(415, "Unsupported Media Type: " <> media_type)
  end

  def handle_errors(conn, _kind, reason, stack) do
    Logger.error("Unexpected error: #{inspect(reason)}",
      conn: conn,
      crash_reason: {reason, stack}
    )

    conn |> Respond.error(500, "Internal Server Error")
  end
end
