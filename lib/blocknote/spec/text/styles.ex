defmodule BlockNote.Spec.Text.Styles do
  @moduledoc """
  Proof of concept
  """

  @type t :: %{
          optional(:bold) => boolean(),
          optional(:italic) => boolean(),
          optional(:text_color) => String.t(),
          optional(:background_color) => String.t()
        }
end
