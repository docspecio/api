defmodule DocSpec.Util.Color.RGB.Hex do
  @moduledoc """
  Utilities for working with hex color strings.

  This module provides helpers to convert various hex color formats
  into 8-bit sRGB tuples understood by `DocSpec.Util.Color.RGB`.

  Supported input formats:

    * `"#RRGGBB"` — hex with leading hash
    * `"RRGGBB"` — hex without hash
    * `"#RGB"`   — shorthand hex with leading hash, expanded to `RRGGBB`
    * `"RGB"`    — shorthand hex without hash, expanded to `RRGGBB`

  The main entry point is `to_rgb/1`, which is non-raising and returns
  `{:ok, rgb}` on success or `{:error, :invalid}` for malformed input.
  """

  @typedoc """
  A hex color string.

  Supported shapes:

    * `"RRGGBB"` — 6 hex digits
    * `"#RRGGBB"` — same with a leading hash
    * `"RGB"` — 3 hex digits, each duplicated (e.g. `"7b6"` → `"77bb66"`)
    * `"#RGB"` — same with a leading hash
  """
  @type t() :: String.t()

  @typedoc """
  Error tuple returned by non-raising color parsing functions.

  Currently only the `:invalid` reason is used, indicating that
  the input could not be interpreted as a hex color.
  """
  @type error() :: {:error, :invalid}

  alias DocSpec.Util.Color.RGB

  @doc """
  Converts a hex color string to an RGB tuple.

  Accepts `"#RRGGBB"`, `"RRGGBB"`, `"#RGB"` and `"RGB"` formats
  and normalises them into an `{r, g, b}` tuple with each component
  in `0..255`.

  The function is non-raising and returns:

    * `{:ok, {r, g, b}}` on success
    * `{:error, :invalid}` when the input is not a valid hex color

  The returned tuple type is compatible with `DocSpec.Util.Color.RGB.t/0`.

  ## Examples

      iex> DocSpec.Util.Color.RGB.Hex.to_rgb("#77bb66")
      {:ok, {119, 187, 102}}

      iex> DocSpec.Util.Color.RGB.Hex.to_rgb("77bb66")
      {:ok, {119, 187, 102}}

      iex> DocSpec.Util.Color.RGB.Hex.to_rgb("#7b6")
      {:ok, {119, 187, 102}}

      iex> DocSpec.Util.Color.RGB.Hex.to_rgb("7b6")
      {:ok, {119, 187, 102}}

      iex> DocSpec.Util.Color.RGB.Hex.to_rgb("#xyz")
      {:error, :invalid}

      iex> DocSpec.Util.Color.RGB.Hex.to_rgb("1234")
      {:error, :invalid}
  """
  @spec to_rgb(color :: t()) :: {:ok, RGB.t()} | error()

  def to_rgb(<<"#", rest::binary>>),
    do: to_rgb(rest)

  def to_rgb(<<r::binary-size(1), g::binary-size(1), b::binary-size(1)>>),
    do: to_rgb(r <> r <> g <> g <> b <> b)

  def to_rgb(<<r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    with {:ok, r} <- parse_component(r),
         {:ok, g} <- parse_component(g),
         {:ok, b} <- parse_component(b) do
      {:ok, {r, g, b}}
    end
  end

  def to_rgb(_),
    do: {:error, :invalid}

  @spec parse_component(<<_::16>>) :: {:ok, 0..255} | error()
  defp parse_component(hex = <<_::binary-size(2)>>) do
    case Integer.parse(hex, 16) do
      {value, ""} when value in 0..255 -> {:ok, value}
      _ -> {:error, :invalid}
    end
  end
end
