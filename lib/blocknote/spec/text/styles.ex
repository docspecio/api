defmodule BlockNote.Spec.Text.Styles do
  @doc """
  Proof of concept
  """

  use TypedStruct

  typedstruct enforce: true do
    field :bold, boolean(), default: false
    field :italic, boolean(), default: false
  end
end
