defmodule DocSpec.API.Plug.Tracing do
  @moduledoc """
  This module provides a Plug that captures a trace ID from the X-Trace-ID header (if set)
  or a request ID from the X-Request-ID header and sets it as Logger metadata for the current
  process. This way, all log messages printed for this request in all later plugs will include the trace ID.

  It also sets the same key for the HTTP Response.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  # coveralls-ignore-next-line
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    header = opts |> Keyword.fetch!(:header)
    key = opts |> Keyword.fetch!(:key)

    value = conn |> get_req_header(header) |> List.first()

    if value do
      Logger.metadata([{key, value}])
      conn |> put_resp_header(header, value)
    else
      conn
    end
  end
end
