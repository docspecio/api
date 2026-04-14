defmodule DocSpec.API.Plug.RawUploadTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias DocSpec.API.Plug.RawUpload

  @docx_content_type "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

  @tag :raw_body
  test "parses raw binary body into Plug.Upload struct" do
    body = <<0, 1, 2, 3, 4>>
    conn = conn(:post, "/", body)

    opts = RawUpload.init(length: 256_000_000, read_length: 1_000_000)

    assert {:ok, %{"file" => %Plug.Upload{} = upload}, %Plug.Conn{}} =
             RawUpload.parse(
               conn,
               "application",
               "vnd.openxmlformats-officedocument.wordprocessingml.document",
               %{},
               opts
             )

    on_exit(fn -> File.rm(upload.path) end)

    assert upload.content_type == @docx_content_type
  end

  @tag :content_type
  test "extracts content-type correctly into Plug.Upload struct" do
    body = "hello world"
    conn = conn(:post, "/", body)

    opts = RawUpload.init(length: 256_000_000, read_length: 1_000_000)

    assert {:ok, %{"file" => %Plug.Upload{content_type: content_type} = upload}, %Plug.Conn{}} =
             RawUpload.parse(conn, "text", "plain", %{}, opts)

    on_exit(fn -> File.rm(upload.path) end)

    assert content_type == "text/plain"
  end

  @tag :multipart
  test "returns {:next, conn} for multipart content-type" do
    conn = conn(:post, "/", "ignored")
    opts = RawUpload.init(length: 256_000_000, read_length: 1_000_000)

    assert {:next, %Plug.Conn{}} =
             RawUpload.parse(conn, "multipart", "form-data", %{}, opts)
  end

  @tag :temp_file
  test "streams body to temp file that exists on disk" do
    body = "temporary upload body"
    conn = conn(:post, "/", body)

    opts = RawUpload.init(length: 256_000_000, read_length: 1_000_000)

    assert {:ok, %{"file" => %Plug.Upload{} = upload}, %Plug.Conn{}} =
             RawUpload.parse(conn, "application", "octet-stream", %{}, opts)

    on_exit(fn -> File.rm(upload.path) end)

    assert File.exists?(upload.path)
    assert File.read!(upload.path) == body
  end

  @tag :size_limit
  test "raises when body exceeds configured length limit" do
    body = "this body is too long"
    conn = conn(:post, "/", body)
    opts = RawUpload.init(length: 10, read_length: 1_000_000)

    assert_raise Plug.Parsers.RequestTooLargeError, fn ->
      RawUpload.parse(conn, "application", "octet-stream", %{}, opts)
    end
  end

  @tag :chunked_streaming
  test "streams large body in multiple chunks within limit" do
    body = String.duplicate("X", 50)
    conn = conn(:post, "/", body)
    opts = RawUpload.init(length: 100, read_length: 10)

    assert {:ok, %{"file" => %Plug.Upload{} = upload}, _conn} =
             RawUpload.parse(conn, "application", "octet-stream", %{}, opts)

    on_exit(fn -> File.rm(upload.path) end)

    assert File.exists?(upload.path)
    assert File.read!(upload.path) == body
  end

  @tag :temp_file_open_error
  test "raises upload error when temp file cannot be opened" do
    path =
      Path.join(
        System.tmp_dir!(),
        "missing-dir-#{System.unique_integer([:positive])}/upload.docx"
      )

    conn =
      conn(:post, "/", "body")
      |> Plug.Conn.put_private(:plug_upload_raw_body_path, path)

    opts = RawUpload.init(length: 256_000_000, read_length: 1_000_000)

    assert_raise Plug.UploadError, ~r/could not open temp file for upload/, fn ->
      RawUpload.parse(conn, "application", "octet-stream", %{}, opts)
    end
  end
end
