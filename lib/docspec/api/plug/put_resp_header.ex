defmodule DocSpec.API.Plug.PutRespHeader do
  @moduledoc """
  This module provides a Plug that puts a specific header on all respones.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  # coveralls-ignore-next-line
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    key = opts |> Keyword.fetch!(:key)
    value = opts |> Keyword.fetch!(:value)

    put_resp_header(conn, key, value)
  end
end
