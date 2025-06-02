defmodule DocSpec.API.Respond do
  @moduledoc """
  Some default responses.
  """

  import Plug.Conn

  @default_expose_headers ["x-trace-id", "x-request-id"]
  @default_allow_headers ["x-trace-id", "x-request-id"]

  @type supported_method() :: :get | :post | :patch | :put | :delete
  @type allow_headers_opt() :: {:allow_headers, [String.t()]}
  @type expose_headers_opt() :: {:expose_headers, [String.t()]}
  @type content_type_opt() :: {:content_type, String.t()}

  @spec respond(
          conn :: Plug.Conn.t(),
          status :: Plug.Conn.status(),
          payload :: Plug.Conn.body(),
          opts :: [expose_headers_opt()]
        ) ::
          Plug.Conn.t() | no_return()
  def respond(conn = %Plug.Conn{}, status, payload, opts \\ []) do
    conn
    |> expose_headers(Keyword.get(opts, :expose_headers, []))
    |> send_resp(status, payload)
  end

  @spec json(
          conn :: Plug.Conn.t(),
          status :: Plug.Conn.status(),
          payload :: term(),
          opts :: [expose_headers_opt()]
        ) ::
          Plug.Conn.t() | no_return()
  def json(conn = %Plug.Conn{}, status, payload, opts \\ []) do
    conn
    |> put_resp_content_type("application/json")
    |> respond(status, Jason.encode!(payload), opts)
  end

  @doc """
  Sends a JSON error response as defined in all DocSpec API specs with the given status and message.
  """
  @spec error(
          conn :: Plug.Conn.t(),
          status :: integer(),
          message :: String.t(),
          opts :: [expose_headers_opt()]
        ) ::
          Plug.Conn.t() | no_return()
  def error(conn, status, message, opts \\ []),
    do: json(conn, status, %{"code" => status, "message" => message}, opts)

  @spec not_found(conn :: Plug.Conn.t(), opts :: [expose_headers_opt()]) :: Plug.Conn.t()
  def not_found(conn = %Plug.Conn{}, opts \\ []),
    do: error(conn, 404, "Not Found", opts)

  @spec head(conn :: Plug.Conn.t(), status :: Plug.Conn.status(), opts :: [expose_headers_opt()]) ::
          Plug.Conn.t() | no_return()
  def head(conn = %Plug.Conn{}, status \\ 200, opts \\ []),
    do: respond(conn, status, [], opts)

  @spec method_not_allowed(conn :: Plug.Conn.t(), supported_methods :: [supported_method()]) ::
          Plug.Conn.t() | no_return()
  def method_not_allowed(conn = %Plug.Conn{}, supported_methods) do
    supported_methods_value = supported_methods_header_value(supported_methods)

    conn
    |> put_resp_header("access-control-allow-methods", supported_methods_value)
    |> put_resp_header("allow", supported_methods_value)
    |> error(405, "Method Not Allowed")
  end

  @spec options(
          conn :: Plug.Conn.t(),
          supported_methods :: [supported_method()],
          opts :: [allow_headers_opt()]
        ) ::
          Plug.Conn.t() | no_return()
  def options(conn = %Plug.Conn{}, supported_methods, opts \\ []) do
    allow_headers = @default_allow_headers ++ Keyword.get(opts, :allow_headers, [])
    supported_methods_value = supported_methods_header_value(supported_methods)

    conn
    |> put_resp_header("access-control-allow-methods", supported_methods_value)
    |> put_resp_header("access-control-allow-headers", Enum.join(allow_headers, ", "))
    |> put_resp_header("allow", supported_methods_value)
    |> send_resp(:no_content, [])
  end

  @spec expose_headers(conn :: Plug.Conn.t(), headers :: [String.t()]) :: Plug.Conn.t()
  def expose_headers(conn = %Plug.Conn{}, headers) do
    put_resp_header(
      conn,
      "access-control-expose-headers",
      Enum.join(@default_expose_headers ++ headers, ", ")
    )
  end

  @spec supported_methods_header_value(supported_methods :: [supported_method()]) :: String.t()
  defp supported_methods_header_value(supported_methods) do
    Enum.map_join(supported_methods, ", ", fn method ->
      method |> Atom.to_string() |> String.upcase()
    end)
  end
end
