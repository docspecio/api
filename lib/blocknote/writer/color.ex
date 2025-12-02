defmodule BlockNote.Writer.Color do
  @moduledoc """
  Color helpers for the BlockNote writer.

  This module exposes a palette of named colors compatible with the
  BlockNote editor and provides a `nearest/1` function that maps an
  arbitrary color to the closest BlockNote color name in 8-bit sRGB
  space.

  Colors can be supplied either as:

    * hex color strings (`"#RRGGBB"`, `"RRGGBB"`, `"#RGB"`, `"RGB"`)
    * RGB tuples `{r, g, b}` with 8-bit components (`0..255`)

  Internally, the comparison is done in 8-bit sRGB space using squared
  Euclidean distance over the RGB channels.
  """

  alias DocSpec.Util.Color.RGB

  require RGB

  @colors [
    {"gray", "#9b9a97"},
    {"brown", "#64473a"},
    {"red", "#e03e3e"},
    {"orange", "#d9730d"},
    {"yellow", "#dfab01"},
    {"green", "#4d6461"},
    {"blue", "#0b6e99"},
    {"purple", "#6940a5"},
    {"pink", "#ad1a72"}
  ]

  # {name, {r, g, b}} — 8-bit sRGB
  @rgb_palette (for {name, hex} <- @colors do
                  {:ok, rgb} = RGB.Hex.to_rgb(hex)
                  {name, rgb}
                end)

  @typedoc """
  The name of a BlockNote color in the built-in palette.

  Examples include `"red"`, `"orange"`, `"blue"`, etc.
  """
  @type name() :: String.t()

  @typedoc """
  Any color accepted by `nearest/1`.

  This can be either:

    * an 8-bit sRGB tuple, as defined by `DocSpec.Util.Color.RGB.t/0`
    * a hex color string, as defined by `DocSpec.Util.Color.RGB.Hex.t/0`
  """
  @type color() :: RGB.t() | RGB.Hex.t()

  @typedoc """
  Error type returned when a color cannot be interpreted.

  This is delegated from `DocSpec.Util.Color.RGB.Hex.error/0` and is
  currently `{:error, :invalid}` for malformed hex input.
  """
  @type error() :: RGB.Hex.error()

  @doc """
  Returns the nearest BlockNote color name for a given color.

  Accepts:

    * a hex string (`"#RRGGBB"`, `"RRGGBB"`, `"#RGB"`, `"RGB"`)
    * an 8-bit sRGB tuple `{r, g, b}` with each component in `0..255`

  On success returns `{:ok, name}` where `name` is one of the BlockNote
  palette names defined in this module. If the input is not a valid
  hex string or RGB tuple, returns `{:error, :invalid}`.

  The comparison is done in 8-bit sRGB space using squared Euclidean
  distance on the RGB channels against the fixed BlockNote palette.

  ## Examples

      iex> BlockNote.Writer.Color.nearest("#d9730d")
      {:ok, "orange"}

      iex> BlockNote.Writer.Color.nearest("#64473a")
      {:ok, "brown"}

      iex> BlockNote.Writer.Color.nearest({224, 62, 62})
      {:ok, "red"}

      iex> BlockNote.Writer.Color.nearest("not-a-color")
      {:error, :invalid}
  """
  @spec nearest(color()) :: {:ok, name()} | error()
  def nearest(color) when is_binary(color) do
    with {:ok, rgb} <- RGB.Hex.to_rgb(color) do
      nearest(rgb)
    end
  end

  def nearest(rgb) when RGB.is_rgb(rgb) do
    {name, _dist} =
      Enum.reduce(
        @rgb_palette,
        nil,
        fn
          {name, rgb_candidate}, acc = {_name, current_distance} ->
            distance = RGB.distance_sq(rgb, rgb_candidate)

            if distance < current_distance do
              {name, distance}
            else
              acc
            end

          {name, rgb_candidate}, nil ->
            {name, RGB.distance_sq(rgb, rgb_candidate)}
        end
      )

    {:ok, name}
  end
end
