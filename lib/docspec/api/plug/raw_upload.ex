defmodule DocSpec.API.Plug.RawUpload do
  @moduledoc """
  Plug.Parsers behaviour that reads the raw request body and stores it as a
  Plug.Upload struct, keyed as "file" in conn.params.

  Multipart content types are rejected (returns {:next, conn}) so they fall
  through to the next parser or raise UnsupportedMediaTypeError.
  """
  @behaviour Plug.Parsers

  @impl true
  def init(opts) do
    [
      length: Keyword.get(opts, :length, 256_000_000),
      read_length: Keyword.get(opts, :read_length, 1_000_000)
    ]
  end

  @impl true
  def parse(conn, type, subtype, _params, opts) do
    if type == "multipart" do
      {:next, conn}
    else
      add_body_as_file(conn, type, subtype, opts)
    end
  end

  defp add_body_as_file(conn, type, subtype, opts) do
    ext = MIME.extensions("#{type}/#{subtype}") |> List.first() || "bin"
    filename = "upload-#{:erlang.unique_integer([:positive])}.#{ext}"
    path = Map.get(conn.private, :plug_upload_raw_body_path, Plug.Upload.random_file!("raw"))

    case File.open(path, [:write, :binary, :delayed_write, :raw]) do
      {:ok, file} ->
        try do
          case stream_body_to_file(conn, file, opts) do
            {:ok, updated_conn} ->
              upload = %Plug.Upload{
                content_type: "#{type}/#{subtype}",
                filename: filename,
                path: path
              }

              {:ok, %{"file" => upload}, updated_conn}

            {:error, :too_large, _conn} ->
              File.rm(path)
              raise Plug.Parsers.RequestTooLargeError

            {:error, reason} ->
              File.rm(path)
              raise Plug.UploadError, "could not handle upload due to: #{inspect(reason)}"
          end
        rescue
          exception ->
            File.rm(path)
            reraise exception, __STACKTRACE__
        catch
          kind, reason ->
            File.rm(path)
            :erlang.raise(kind, reason, __STACKTRACE__)
        after
          File.close(file)
        end

      {:error, reason} ->
        raise Plug.UploadError, "could not open temp file for upload: #{inspect(reason)}"
    end
  end

  defp stream_body_to_file(conn, file, opts) do
    length = Keyword.fetch!(opts, :length)
    read_length = Keyword.fetch!(opts, :read_length)

    do_stream(conn, file, length, read_length)
  end

  defp do_stream(conn, file, remaining, read_length) do
    chunk_length = min(remaining, read_length)

    case Plug.Conn.read_body(conn, length: chunk_length, read_length: read_length) do
      {:ok, data, conn} ->
        :ok = IO.binwrite(file, data)
        {:ok, conn}

      {:more, chunk, conn} ->
        write_and_continue(conn, file, chunk, remaining, read_length)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp write_and_continue(conn, file, chunk, remaining, read_length) do
    next_remaining = remaining - byte_size(chunk)

    if next_remaining <= 0 do
      {:error, :too_large, conn}
    else
      :ok = IO.binwrite(file, chunk)
      do_stream(conn, file, next_remaining, read_length)
    end
  end
end
