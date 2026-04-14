defmodule DocSpec.API.Plug.ProblemDetailsTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias DocSpec.API.Plug.ProblemDetails

  @problem_headers [
    {"cache-control", "max-age=0, private, must-revalidate"},
    {"content-type", "application/problem+json; charset=utf-8"},
    {"access-control-expose-headers", "x-trace-id, x-request-id"}
  ]

  test "send/4 returns correct RFC 7807 response" do
    conn = conn(:get, "/")

    {status, headers, body} =
      conn
      |> ProblemDetails.send(400, "Bad Request", "Something was bad")
      |> sent_resp()

    assert status == 400
    assert headers == @problem_headers

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Bad Request",
             "status" => 400,
             "detail" => "Something was bad"
           }
  end

  test "bad_request/2 returns 400" do
    conn = conn(:get, "/")

    {status, headers, body} =
      conn
      |> ProblemDetails.bad_request("Request body is empty")
      |> sent_resp()

    assert status == 400
    assert headers == @problem_headers

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Bad Request",
             "status" => 400,
             "detail" => "Request body is empty"
           }
  end

  test "not_acceptable/2 returns 406" do
    conn = conn(:get, "/")

    {status, headers, body} =
      conn
      |> ProblemDetails.not_acceptable(
        "Accept header must be application/vnd.docspec.blocknote+json"
      )
      |> sent_resp()

    assert status == 406
    assert headers == @problem_headers

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Not Acceptable",
             "status" => 406,
             "detail" => "Accept header must be application/vnd.docspec.blocknote+json"
           }
  end

  test "payload_too_large/2 returns 413" do
    conn = conn(:get, "/")

    {status, headers, body} =
      conn
      |> ProblemDetails.payload_too_large("Request body exceeds maximum size of 256 MB")
      |> sent_resp()

    assert status == 413
    assert headers == @problem_headers

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Payload Too Large",
             "status" => 413,
             "detail" => "Request body exceeds maximum size of 256 MB"
           }
  end

  test "unsupported_media_type/2 returns 415" do
    conn = conn(:get, "/")

    {status, headers, body} =
      conn
      |> ProblemDetails.unsupported_media_type(
        "Content-Type must be application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      )
      |> sent_resp()

    assert status == 415
    assert headers == @problem_headers

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Unsupported Media Type",
             "status" => 415,
             "detail" =>
               "Content-Type must be application/vnd.openxmlformats-officedocument.wordprocessingml.document"
           }
  end

  test "unprocessable_entity/2 returns 422" do
    conn = conn(:get, "/")

    {status, headers, body} =
      conn
      |> ProblemDetails.unprocessable_entity("Document could not be parsed as valid DOCX")
      |> sent_resp()

    assert status == 422
    assert headers == @problem_headers

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Unprocessable Content",
             "status" => 422,
             "detail" => "Document could not be parsed as valid DOCX"
           }
  end

  test "internal_server_error/2 returns 500" do
    conn = conn(:get, "/")

    {status, headers, body} =
      conn
      |> ProblemDetails.internal_server_error("An unexpected error occurred during conversion")
      |> sent_resp()

    assert status == 500
    assert headers == @problem_headers

    assert Jason.decode!(body) == %{
             "type" => "about:blank",
             "title" => "Internal Server Error",
             "status" => 500,
             "detail" => "An unexpected error occurred during conversion"
           }
  end
end
