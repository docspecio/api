defmodule DocSpec.API.Plug.TracingTest do
  alias DocSpec.API.Plug.Tracing

  use ExUnit.Case, async: true

  require Logger

  import Plug.Test
  import Plug.Conn

  doctest Tracing

  test "sets Logger metadata and response header when header is present" do
    opts = Tracing.init(header: "x-request-id", key: "http.request.id")

    conn =
      conn(:get, "/")
      |> put_req_header("x-request-id", "test-id-123")
      |> Tracing.call(opts)

    assert conn.resp_headers == [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"x-request-id", "test-id-123"}
           ]

    assert List.keyfind(Logger.metadata(), "http.request.id", 0) ==
             {"http.request.id", "test-id-123"}
  end

  test "passes through unchanged when header is absent" do
    opts = Tracing.init(header: "x-request-id", key: "http.request.id")

    conn =
      conn(:get, "/")
      |> Tracing.call(opts)

    assert conn.resp_headers == [
             {"cache-control", "max-age=0, private, must-revalidate"}
           ]
  end
end
