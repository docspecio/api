defmodule BlockNote.Spec.Text do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  alias BlockNote.Spec.Text.Styles

  typedstruct enforce: true do
    field :type, :text, default: :text
    field :text, String.t()
    field :styles, Styles.t(), default: %{}
  end
end
