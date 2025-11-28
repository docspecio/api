defmodule DocSpec.Util.Color.RGB do
  @moduledoc """
  Utilities for working with 8-bit sRGB colors.

  This module provides:

    * a structural type for RGB colors (`t/0`)
    * guards for validating RGB components and tuples (`is_rgb_component/1`, `is_rgb/3`, `is_rgb/1`)
    * distance metrics in RGB space (`distance_sq/2` and `distance/2`)

  All colors are represented as `{r, g, b}` tuples where each component
  is an integer in the `0..255` range.
  """

  @typedoc """
  An 8-bit sRGB color.

  Each element is an integer in the `0..255` range:

    * `r` — red channel
    * `g` — green channel
    * `b` — blue channel
  """
  @type t() :: {0..255, 0..255, 0..255}

  # coveralls-ignore-start

  @doc """
  Guard that matches a single 8-bit RGB component.

  Succeeds when `c` is an integer in the `0..255` range, otherwise
  the guard fails.

  This is intended for use in function heads and other guards:

      def foo(c) when RGB.is_rgb_component(c) do
        ...
      end
  """
  defguard is_rgb_component(c)
           when is_integer(c) and c >= 0 and c <= 255

  @doc """
  Guard that matches three 8-bit RGB channel values.

  Succeeds when all of `r`, `g` and `b` are integers in the `0..255`
  range, making it suitable for validating color components directly in
  function heads:

      def bar(r, g, b) when RGB.is_rgb(r, g, b) do
        ...
      end
  """
  defguard is_rgb(r, g, b)
           when is_rgb_component(r) and
                  is_rgb_component(g) and
                  is_rgb_component(b)

  @doc """
  Guard that matches an `{r, g, b}` RGB tuple.

  Succeeds when:

    * `rgb` is a 3-element tuple
    * each element is an integer in the `0..255` range

  This guard is useful for validating color tuples in function heads:

      def baz(rgb) when RGB.is_rgb(rgb) do
        ...
      end
  """
  defguard is_rgb(rgb)
           when is_tuple(rgb) and
                  tuple_size(rgb) == 3 and
                  is_rgb(elem(rgb, 0), elem(rgb, 1), elem(rgb, 2))

  # coveralls-ignore-stop

  @doc """
  Squared Euclidean distance between two 8-bit sRGB colors.

  Computes the squared distance directly on the 0..255 channels:

      (r₁ - r₂)² + (g₁ - g₂)² + (b₁ - b₂)²

  This is intentionally left unsquared to avoid the cost of
  `:math.sqrt/1` when you only need to compare distances:

    * nearest-neighbour search
    * thresholding
    * ordering by distance

  The arguments must be valid RGB tuples; invalid inputs are rejected
  by the guard in the function head.

  ## Examples

      iex> c1 = {42, 100, 200}
      iex> c2 = {45, 104, 212}
      iex> DocSpec.Util.Color.RGB.distance_sq(c1, c2)
      169.0

      iex> DocSpec.Util.Color.RGB.distance_sq({123, 99, 211}, {123, 99, 211})
      0.0
  """
  @spec distance_sq(t(), t()) :: float()
  def distance_sq({r1, g1, b1}, {r2, g2, b2}) when is_rgb(r1, g1, b1) and is_rgb(r2, g2, b2) do
    dr = r1 - r2
    dg = g1 - g2
    db = b1 - b2

    total = dr * dr + dg * dg + db * db
    total * 1.0
  end

  @doc """
  Euclidean distance between two 8-bit sRGB colors.

  This is the square root of `distance_sq/2`:

      :math.sqrt(distance_sq(c1, c2))

  Use this when you actually need the metric distance (for example for
  user-facing values) rather than just ordering by distance.

  ## Examples

      iex> DocSpec.Util.Color.RGB.distance({42, 100, 200}, {45, 104, 212})
      13.0
  """
  @spec distance(t(), t()) :: float()
  def distance(c1, c2) when is_rgb(c1) and is_rgb(c2),
    do: :math.sqrt(distance_sq(c1, c2))
end
