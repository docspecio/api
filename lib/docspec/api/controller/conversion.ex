defmodule DocSpec.API.Controller.Conversion do
  @moduledoc """
  Router for conversion API.
  """

  use Plug.Builder

  import Plug.Conn

  require Logger

  alias DocSpec.API.Plug.AcceptValidator
  alias DocSpec.API.Plug.ProblemDetails
  alias DocSpec.API.Plug.RawUpload
  alias DocSpec.API.Respond
  alias DocSpec.Core.BlockNote.Writer, as: BlockNoteWriter
  alias DocSpec.Core.DOCX

  @docx "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  @blocknote ["application/vnd.docspec.blocknote+json", "application/vnd.blocknote+json"]

  plug AcceptValidator, accept: @blocknote
  plug :default_content_type
  plug :parse_body
  plug :handle

  def default_content_type(conn = %Plug.Conn{method: "POST"}, _opts) do
    case get_req_header(conn, "content-type") do
      [] -> put_req_header(conn, "content-type", @docx)
      _ -> conn
    end
  end

  def default_content_type(conn, _opts), do: conn

  def parse_body(conn = %Plug.Conn{method: "POST"}, _opts) do
    if @docx == content_type(conn) do
      max_size = Application.get_env(:docspec_api, :max_upload_size, 256_000_000)

      opts =
        Plug.Parsers.init(
          parsers: [RawUpload],
          length: max_size,
          read_length: 1_000_000,
          pass: ["*/*"]
        )

      Plug.Parsers.call(conn, opts)
    else
      conn
    end
  end

  def parse_body(conn, _opts), do: conn

  def handle(conn = %Plug.Conn{method: "POST"}, _opts) do
    case {content_type(conn), conn.params} do
      {"multipart/" <> _, _params} ->
        ProblemDetails.unsupported_media_type(
          conn,
          "Multipart uploads are not supported. Send raw binary body."
        )

      {@docx, %{"file" => %Plug.Upload{path: path}}} ->
        convert(conn, path)

      {@docx, _params} ->
        ProblemDetails.bad_request(conn, "Request body is empty")

      _ ->
        ProblemDetails.unsupported_media_type(
          conn,
          "Content-Type must be #{@docx}"
        )
    end
  end

  def handle(conn = %Plug.Conn{method: "OPTIONS"}, _opts),
    do: Respond.options(conn, [:post])

  def handle(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_header("access-control-allow-methods", "POST")
    |> Plug.Conn.put_resp_header("allow", "POST")
    |> ProblemDetails.send(405, "Method Not Allowed", "Only POST is supported on this endpoint.")
  end

  defp convert(conn, path) do
    case File.stat(path) do
      {:ok, %{size: 0}} ->
        ProblemDetails.bad_request(conn, "Request body is empty")

      {:ok, _stat} ->
        with {:ok, document_spec} <- read_document_spec(path),
             {:ok, blocknote} <- BlockNoteWriter.write(document_spec) do
          conn
          |> Plug.Conn.put_resp_content_type(accepted_content_type(conn))
          |> Respond.respond(200, Jason.encode!(DocSpec.JSON.to_encodable(blocknote)))
        else
          {:error, :invalid_docx} ->
            ProblemDetails.unprocessable_entity(
              conn,
              "Document could not be parsed as valid DOCX"
            )
        end

      {:error, _reason} ->
        ProblemDetails.bad_request(conn, "Request body is empty")
    end
  after
    File.rm(path)
  end

  defp read_document_spec(path) do
    docx = DOCX.Reader.open!(path)

    try do
      document_spec = DOCX.Reader.convert!(docx)
      {:ok, document_spec}
    after
      DOCX.Reader.close!(docx)
    end
  rescue
    _error in [RuntimeError, ArgumentError, File.Error, Saxy.ParseError] ->
      {:error, :invalid_docx}
  catch
    :throw, _reason ->
      {:error, :invalid_docx}
  end

  defp content_type(conn) do
    case Plug.Conn.get_req_header(conn, "content-type") do
      [value | _rest] ->
        case Plug.Conn.Utils.content_type(value) do
          {:ok, type, subtype, _params} -> "#{type}/#{subtype}"
          :error -> value
        end

      [] ->
        nil
    end
  end

  defp accepted_content_type(conn) do
    case get_req_header(conn, "accept") do
      [accept | _] when accept != "*/*" -> accept
      _ -> List.first(@blocknote)
    end
  end
end
