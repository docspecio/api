defmodule DocSpec.API.Plug.AcceptValidatorTest do
  @valid_accept "application/vnd.docspec.blocknote+json"

  use ExUnit.Case,
    async: true,
    parameterize: [
      %{init_opts: [accept: @valid_accept]},
      %{init_opts: [accept: ["text/html", @valid_accept, "text/plain"]]}
    ]

  import Plug.Test
  import Plug.Conn

  alias DocSpec.API.Plug.AcceptValidator

  test "passes through when Accept header matches", %{init_opts: init_opts} do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", @valid_accept)
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when Accept header in acceptable values", %{init_opts: init_opts} do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", @valid_accept)
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when Accept header is missing", %{init_opts: init_opts} do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "halts with 406 when Accept header is wrong", %{init_opts: init_opts} do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "application/xml")
      |> AcceptValidator.call(opts)

    assert conn.halted

    {status, headers, body} = sent_resp(conn)

    assert status == 406

    assert headers == [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-type", "application/problem+json; charset=utf-8"},
             {"access-control-expose-headers", "x-trace-id, x-request-id"}
           ]

    accepted = init_opts[:accept] |> List.wrap() |> Enum.join(" or ")

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Not Acceptable",
             "status" => 406,
             "detail" => "Accept header must include #{accepted}"
           }
  end

  test "passes through when Accept is */*", %{init_opts: init_opts} do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "*/*")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when Accept contains required type among multiple values", %{
    init_opts: init_opts
  } do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "application/vnd.docspec.blocknote+json, application/xml")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when Accept contains wildcard with quality parameter", %{
    init_opts: init_opts
  } do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "application/xml, */*;q=0.8")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "passes through when required type has quality parameter", %{init_opts: init_opts} do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "#{@valid_accept};q=1.0")
      |> AcceptValidator.call(opts)

    refute conn.halted
  end

  test "halts with 406 when Accept has multiple values but none match", %{init_opts: init_opts} do
    opts = AcceptValidator.init(init_opts)

    conn =
      conn(:post, "/")
      |> put_req_header("accept", "application/xml, application/json")
      |> AcceptValidator.call(opts)

    assert conn.halted

    {status, headers, body} = sent_resp(conn)

    assert status == 406

    assert headers == [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-type", "application/problem+json; charset=utf-8"},
             {"access-control-expose-headers", "x-trace-id, x-request-id"}
           ]

    accepted = init_opts[:accept] |> List.wrap() |> Enum.join(" or ")

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Not Acceptable",
             "status" => 406,
             "detail" => "Accept header must include #{accepted}"
           }
  end
end
