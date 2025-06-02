defmodule DocSpec.API.Plug.ErrorHandler do
  @moduledoc """
  A module to be used in your existing plugs in order to provide
  error handling.

      defmodule AppRouter do
        use Plug.Router
        use DocSpec.API.Plug.ErrorHandler

        plug :match
        plug :dispatch

        get "/hello" do
          send_resp(conn, 200, "world")
        end

        @impl DocSpec.API.Plug.ErrorHandler
        def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
          send_resp(conn, 500, "Something went wrong")
        end
      end

  Once this module is used, a callback named `handle_errors/2` should
  be defined in your plug. This callback will receive the connection
  already updated with a proper status code for the given exception.
  The second argument is a map containing:

    * the exception kind (`:throw`, `:error` or `:exit`),
    * the reason (an exception for errors or a term for others)
    * the stacktrace

  After the callback is invoked, the error is re-raised.

  It is advised to do as little work as possible when handling errors
  and avoid accessing data like parameters and session, as the parsing
  of those is what could have led the error to trigger in the first place.

  Also notice that these pages are going to be shown in production. If
  you are looking for error handling to help during development, consider
  using `Plug.Debugger`.

  **Note:** If this module is used with `Plug.Debugger`, it must be used
  after `Plug.Debugger`.
  """

  @doc """
  Handle errors from plugs.

  Called when an exception is raised during the processing of a plug.
  """
  @callback handle_errors(
              conn :: Plug.Conn.t(),
              kind :: :error | :throw | :exit,
              reason :: Exception.t() | term(),
              stack :: Exception.stacktrace()
            ) :: Plug.Conn.t()

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @before_compile DocSpec.API.Plug.ErrorHandler
      @behaviour DocSpec.API.Plug.ErrorHandler
    end
  end

  @spec __before_compile__(any()) ::
          {:__block__, [{:keep, {any(), any()}}, ...],
           [{:def, [...], [...]} | {:defoverridable, [...], [...]}, ...]}
  @doc false
  defmacro __before_compile__(_env) do
    quote location: :keep do
      defoverridable call: 2

      def call(conn, opts) do
        super(conn, opts)
      rescue
        e in Plug.Conn.WrapperError ->
          %{conn: conn, kind: kind, reason: reason, stack: stack} = e
          handle_errors(conn, kind, reason, __STACKTRACE__)
      catch
        kind, reason ->
          handle_errors(conn, kind, reason, __STACKTRACE__)
      end
    end
  end
end
