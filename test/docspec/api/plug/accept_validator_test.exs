defmodule DocSpec.API.Plug.AcceptValidatorTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias DocSpec.API.Plug.AcceptValidator

  @valid_accept "application/vnd.docspec.blocknote+json"

  test "passes through when Accept header matches exactly" do
    opts = AcceptValidator.init(accept: @valid_accept)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", @valid_accept)
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when Accept header is missing" do
    opts = AcceptValidator.init(accept: @valid_accept)

    conn =
      conn(:post, "/")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "halts with 406 when Accept header is wrong" do
    opts = AcceptValidator.init(accept: @valid_accept)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "text/html")
      |> AcceptValidator.call(opts)

    assert conn.halted

    {status, headers, body} = sent_resp(conn)

    assert status == 406

    assert headers == [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-type", "application/problem+json; charset=utf-8"},
             {"access-control-expose-headers", "x-trace-id, x-request-id"}
           ]

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Not Acceptable",
             "status" => 406,
             "detail" => "Accept header must include #{@valid_accept}"
           }
  end

  test "passes through when Accept is */*" do
    opts = AcceptValidator.init(accept: @valid_accept)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "*/*")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when Accept contains required type among multiple values" do
    opts = AcceptValidator.init(accept: @valid_accept)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "application/vnd.docspec.blocknote+json, text/html")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when Accept contains wildcard with quality parameter" do
    opts = AcceptValidator.init(accept: @valid_accept)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "text/html, */*;q=0.8")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when required type has quality parameter" do
    opts = AcceptValidator.init(accept: @valid_accept)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "#{@valid_accept};q=1.0")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "halts with 406 when Accept has multiple values but none match" do
    opts = AcceptValidator.init(accept: @valid_accept)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "text/html, application/json")
      |> AcceptValidator.call(opts)

    assert conn.halted

    {status, headers, body} = sent_resp(conn)

    assert status == 406

    assert headers == [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-type", "application/problem+json; charset=utf-8"},
             {"access-control-expose-headers", "x-trace-id, x-request-id"}
           ]

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Not Acceptable",
             "status" => 406,
             "detail" => "Accept header must include #{@valid_accept}"
           }
  end
end
