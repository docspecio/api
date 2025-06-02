defmodule DocSpec.API.Plug.RawUpload do
  @moduledoc """
  This module handles the combination of content type and raw body as an upload.
  """
  @behaviour Plug.Parsers

  @impl true
  # coveralls-ignore-next-line
  def init(opts) do
    [
      length: Keyword.get(opts, :length, 8_000_000),
      read_length: Keyword.get(opts, :read_length, 1_000_000)
    ]
  end

  @impl true
  def parse(conn, type, subtype, params, opts) do
    if supported_content_type(type, subtype) do
      add_body_as_file(conn, type, subtype, params, opts)
    else
      {:next, conn}
    end
  end

  @spec supported_content_type(type :: String.t(), subtype :: String.t()) :: boolean()
  defp supported_content_type(type, _subtype),
    do: type != "multipart"

  @spec add_body_as_file(
          conn :: Plug.Conn.t(),
          type :: String.t(),
          subtype :: String.t(),
          params :: Plug.Conn.Utils.params(),
          opts :: Keyword.t()
        ) :: {:ok, Plug.Conn.params(), Plug.Conn.t()}
  defp add_body_as_file(conn, type, subtype, _params, opts) do
    filename = "raw-#{:erlang.unique_integer([:positive])}"

    with path <- Plug.Upload.random_file!("raw"),
         {:ok, file} = File.open(path, [:write, :binary, :delayed_write, :raw]),
         {:ok, conn} <- stream_body_to_file(conn, file, opts),
         :ok <- File.close(file) do
      {:ok, %{"file" => make_upload(type, subtype, filename, path)}, conn}
    else
      {:error, error} ->
        raise Plug.UploadError, "could not handle upload due to: #{error}"
    end
  end

  @spec stream_body_to_file(conn :: Plug.Conn.t(), file :: IO.device(), opts :: keyword()) ::
          {:ok, Plug.Conn.t()} | {:error, term()}
  defp stream_body_to_file(conn, file, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, data, conn} ->
        IO.binwrite(file, data)
        {:ok, conn}

      {:more, chunk, conn} ->
        IO.binwrite(file, chunk)
        stream_body_to_file(conn, file, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec make_upload(
          type :: String.t(),
          subtype :: String.t(),
          filename :: String.t(),
          path :: String.t()
        ) :: Plug.Upload.t()
  defp make_upload(type, subtype, filename, path),
    do: %Plug.Upload{content_type: "#{type}/#{subtype}", filename: filename, path: path}
end
