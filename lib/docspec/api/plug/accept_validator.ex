defmodule DocSpec.API.Plug.AcceptValidator do
  @moduledoc """
  Plug that validates the Accept header against a required value.

  Parses the comma-separated Accept header and accepts the request if any
  media type matches the configured value or is a wildcard (`*/*`). Quality
  parameters (e.g. `;q=0.8`) are stripped before comparison. Halts with
  406 Not Acceptable (RFC 7807) when no match is found.
  Missing Accept defaults to the required value.

  ## Usage

      plug DocSpec.API.Plug.AcceptValidator,
        accept: "application/vnd.docspec.blocknote+json"
  """

  @behaviour Plug

  import Plug.Conn

  alias DocSpec.API.Plug.ProblemDetails

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn = %Plug.Conn{method: "POST"}, opts) do
    required = Keyword.fetch!(opts, :accept)

    case get_req_header(conn, "accept") do
      [] ->
        conn

      values ->
        accept = Enum.join(values, ", ")

        if accepts?(accept, required) do
          conn
        else
          conn
          |> ProblemDetails.not_acceptable("Accept header must include #{required}")
          |> halt()
        end
    end
  end

  def call(conn, _opts), do: conn

  defp accepts?(accept, required) do
    required = String.downcase(required)

    accept
    |> String.split(",")
    |> Enum.any?(fn part ->
      media_type =
        part
        |> String.split(";")
        |> List.first()
        |> String.trim()
        |> String.downcase()

      media_type == required or media_type == "*/*"
    end)
  end
end
