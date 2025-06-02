defmodule BlockNote.Spec.Heading.Props do
  @doc """
  Proof of concept
  """

  use TypedStruct

  typedstruct enforce: true do
    field :level, integer()
  end
end
