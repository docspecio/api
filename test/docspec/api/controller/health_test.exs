defmodule DocSpec.API.Controller.HealthTest do
  alias DocSpec.API.Controller.Health

  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  doctest Health

  @opts Health.init([])

  describe "GET /health" do
    test "returns 200 with 'Healthy.'" do
      conn =
        :get
        |> conn("/health")
        |> Health.call(@opts)

      assert conn.status == 200
      assert conn.resp_body == "Healthy."
    end
  end

  describe "HEAD /health" do
    test "returns 204 no content" do
      conn =
        :head
        |> conn("/health")
        |> Health.call(@opts)

      assert conn.status == Plug.Conn.Status.code(:no_content)
      # Depending on Respond.respond implementation this might be "" or nil
      assert conn.resp_body in [nil, ""]
    end
  end

  describe "OPTIONS /health" do
    test "returns allowed methods" do
      conn =
        :options
        |> conn("/health")
        |> Health.call(@opts)

      assert conn.status == Plug.Conn.Status.code(:no_content)

      [allow_header] = get_resp_header(conn, "allow")

      assert allow_header == "GET, HEAD, OPTIONS"
    end
  end

  describe "other methods" do
    test "returns 405 method not allowed for unsupported methods" do
      conn =
        :post
        |> conn("/health")
        |> Health.call(@opts)

      assert conn.status == Plug.Conn.Status.code(:method_not_allowed)

      assert conn.resp_headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-methods", "GET, HEAD, OPTIONS"},
               {"allow", "GET, HEAD, OPTIONS"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert %{
               "type" => "about:blank",
               "title" => "Method Not Allowed",
               "status" => 405,
               "detail" => "Allowed methods: GET, HEAD, OPTIONS."
             } ==
               Jason.decode!(conn.resp_body)
    end
  end
end
