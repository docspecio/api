defmodule DocSpec.API.Controller.Health do
  @moduledoc """
  Endpoint that indicates service is started.
  """

  use Plug.Builder

  alias DocSpec.API.Respond

  plug :handle

  @methods [:get, :head, :options]

  def handle(conn = %Plug.Conn{method: "OPTIONS"}, _opts),
    do: Respond.options(conn, @methods)

  def handle(conn = %Plug.Conn{method: "HEAD"}, _opts),
    do: Respond.respond(conn, :no_content, [])

  def handle(conn = %Plug.Conn{method: "GET"}, _opts),
    do: Respond.respond(conn, 200, "Healthy.")

  def handle(conn, _opts),
    do: Respond.method_not_allowed(conn, @methods)
end
