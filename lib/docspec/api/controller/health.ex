defmodule DocSpec.API.Controller.Health do
  @moduledoc """
  Endpoint that indicates service is started.
  """

  use Plug.Builder

  alias DocSpec.API.Plug.ProblemDetails
  alias DocSpec.API.Respond

  plug :handle

  @methods [:get, :head, :options]

  def handle(conn = %Plug.Conn{method: "OPTIONS"}, _opts),
    do: Respond.options(conn, @methods)

  def handle(conn = %Plug.Conn{method: "HEAD"}, _opts),
    do: Respond.respond(conn, :no_content, [])

  def handle(conn = %Plug.Conn{method: "GET"}, _opts),
    do: Respond.respond(conn, 200, "Healthy.")

  def handle(conn, _opts) do
    allowed = Enum.map_join(@methods, ", ", &(&1 |> Atom.to_string() |> String.upcase()))

    conn
    |> Plug.Conn.put_resp_header("access-control-allow-methods", allowed)
    |> Plug.Conn.put_resp_header("allow", allowed)
    |> ProblemDetails.send(405, "Method Not Allowed", "Allowed methods: #{allowed}.")
  end
end
