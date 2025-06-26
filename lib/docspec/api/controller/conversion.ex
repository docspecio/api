defmodule DocSpec.API.Controller.Conversion do
  @moduledoc """
  Router for conversion API.
  """

  use Plug.Builder

  require Logger

  alias DocSpec.API.Respond
  alias NLdoc.Conversion.Reader.Docx

  plug Plug.Parsers,
    parsers: [{:multipart, validate_utf8: false, length: 256_000_000}],
    pass: ["*/*"]

  plug :handle

  def handle(conn = %Plug.Conn{method: "POST"}, _opts) do
    with {:ok, %Plug.Upload{path: path}} <- first_file(conn),
         docx = %Docx{} <- Docx.open!(path),
         document <- Docx.convert!(docx),
         :ok <- Docx.close!(docx),
         {:ok, blocknote} <- DocSpec.Writer.BlockNote.write(document) do
      Respond.json(conn, 200, blocknote |> NLdoc.Util.Recase.to_camel())
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
          %Plug.Upload{
            content_type:
              "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
          } ->
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
