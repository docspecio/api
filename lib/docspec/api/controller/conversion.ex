defmodule DocSpec.API.Controller.Conversion do
  @moduledoc """
  Router for conversion API.
  """

  use Plug.Builder

  require Logger

  alias DocSpec.API.Respond
  alias DocSpec.Core.BlockNote.Writer, as: BlockNoteWriter
  alias DocSpec.Core.DOCX

  @docx "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

  plug Plug.Parsers,
    parsers: [{:multipart, validate_utf8: false, length: 256_000_000}],
    pass: ["*/*"]

  plug :handle

  def handle(conn = %Plug.Conn{method: "POST"}, _opts) do
    with {:ok, %Plug.Upload{path: path}} <- first_file(conn),
         docx <- DOCX.Reader.open!(path),
         document_spec <- DOCX.Reader.convert!(docx),
         :ok <- DOCX.Reader.close!(docx),
         {:ok, blocknote} <- BlockNoteWriter.write(document_spec) do
      Respond.json(conn, 200, DocSpec.JSON.to_encodable(blocknote))
    else
      {:error, :no_upload} ->
        Respond.error(conn, 400, "No DOCX file uploaded.")
    end
  end

  def handle(conn = %Plug.Conn{method: "OPTIONS"}, _opts),
    do: Respond.options(conn, [:post])

  def handle(conn, _opts),
    do: Respond.method_not_allowed(conn, [:post])

  @spec first_file(conn :: Plug.Conn.t()) :: {:ok, Plug.Upload.t()} | {:error, :no_upload}
  defp first_file(conn) do
    upload =
      conn.params
      |> Map.values()
      |> Enum.find(
        nil,
        fn
          %Plug.Upload{content_type: @docx} ->
            true

          _ ->
            false
        end
      )

    if is_nil(upload) do
      {:error, :no_upload}
    else
      {:ok, upload}
    end
  end
end
