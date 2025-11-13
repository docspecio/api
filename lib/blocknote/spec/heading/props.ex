defmodule BlockNote.Spec.Heading.Props do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  typedstruct enforce: true do
    field :level, integer()
  end
end
