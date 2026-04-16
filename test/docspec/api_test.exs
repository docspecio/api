defmodule DocSpec.APITest do
  use ExUnit.Case, async: true

  use Mimic

  alias DocSpec.API

  import Plug.Test
  import Plug.Conn

  doctest API

  describe "using a method that is not supported" do
    test "will respond with 405" do
      assert {status, headers, body} =
               conn(:get, "/conversion")
               |> API.call(API.init([]))
               |> sent_resp()

      assert 405 == status

      assert %{
               "type" => "about:blank",
               "title" => "Method Not Allowed",
               "status" => 405,
               "detail" => "Only POST is supported on this endpoint."
             } ==
               Jason.decode!(body)

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"access-control-allow-methods", "POST"},
               {"allow", "POST"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ] == headers
    end
  end

  describe "requesting the health endpoint" do
    test "returns 200 OK" do
      assert {status, headers, body} =
               conn(:get, "/health")
               |> API.call(API.init([]))
               |> sent_resp()

      assert status == 200

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert body == "Healthy."
    end
  end

  describe "requesting a path that is not defined" do
    test "returns a 404" do
      assert {status, headers, body} =
               conn(:get, "/not-found")
               |> API.call(API.init([]))
               |> sent_resp()

      assert 404 == status

      assert %{
               "type" => "about:blank",
               "title" => "Not Found",
               "status" => 404,
               "detail" => "The requested resource does not exist."
             } ==
               Jason.decode!(body)

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ] == headers
    end
  end

  describe "requesting options for /conversion" do
    test "responds with the allowed options" do
      assert {status, headers, body} =
               conn(:options, "/conversion")
               |> API.call(API.init([]))
               |> sent_resp()

      assert 204 == status

      assert "" == body

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"access-control-allow-methods", "POST"},
               {"access-control-allow-headers", "x-trace-id, x-request-id"},
               {"allow", "POST"}
             ] == headers
    end
  end

  describe "error handling" do
    test "handles UnsupportedMediaTypeError with RFC 7807 415" do
      conn =
        conn(:post, "/conversion")
        |> put_req_header("content-type", "text/plain")

      error = %Plug.Parsers.UnsupportedMediaTypeError{media_type: "text/plain"}

      {status, headers, body} =
        conn
        |> API.handle_errors(%{}, error, [])
        |> sent_resp()

      assert status == 415

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Unsupported Media Type",
               "status" => 415,
               "detail" => "Unsupported media type: text/plain."
             }
    end

    test "handles unexpected errors with RFC 7807 500" do
      conn = conn(:get, "/conversion")

      error = %RuntimeError{message: "Something went wrong"}
      stack = [{SomeModule, :some_function, 1, [file: ~c"lib/some_file.ex", line: 42]}]

      {status, headers, body} =
        conn
        |> API.handle_errors(:error, error, stack)
        |> sent_resp()

      assert status == 500

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Internal Server Error",
               "status" => 500,
               "detail" => "An unexpected error occurred during conversion"
             }
    end
  end
end
