defmodule DocSpec.API.Plug.ProblemDetails do
  @moduledoc """
  RFC 7807 Problem Details for HTTP APIs.

  Sends responses with Content-Type: application/problem+json and a JSON body
  conforming to RFC 7807 / RFC 9457.
  """

  import Plug.Conn

  @type conn :: Plug.Conn.t()

  @doc """
  Sends an RFC 7807 Problem Details response.
  """
  @spec send(conn(), pos_integer(), String.t(), String.t()) :: conn()
  def send(conn, status, title, detail) do
    body =
      Jason.encode!(%{
        "type" => "about:blank",
        "title" => title,
        "status" => status,
        "detail" => detail
      })

    conn
    |> put_resp_content_type("application/problem+json")
    |> DocSpec.API.Respond.expose_headers([])
    |> send_resp(status, body)
  end

  @doc "400 Bad Request"
  @spec bad_request(conn(), String.t()) :: conn()
  def bad_request(conn, detail), do: send(conn, 400, "Bad Request", detail)

  @doc "406 Not Acceptable"
  @spec not_acceptable(conn(), String.t()) :: conn()
  def not_acceptable(conn, detail), do: send(conn, 406, "Not Acceptable", detail)

  @doc "413 Payload Too Large"
  @spec payload_too_large(conn(), String.t()) :: conn()
  def payload_too_large(conn, detail), do: send(conn, 413, "Payload Too Large", detail)

  @doc "415 Unsupported Media Type"
  @spec unsupported_media_type(conn(), String.t()) :: conn()
  def unsupported_media_type(conn, detail), do: send(conn, 415, "Unsupported Media Type", detail)

  @doc "422 Unprocessable Content"
  @spec unprocessable_entity(conn(), String.t()) :: conn()
  def unprocessable_entity(conn, detail), do: send(conn, 422, "Unprocessable Content", detail)

  @doc "500 Internal Server Error"
  @spec internal_server_error(conn(), String.t()) :: conn()
  def internal_server_error(conn, detail), do: send(conn, 500, "Internal Server Error", detail)
end
