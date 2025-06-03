defmodule BlockNote.Spec.Table.Cell do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :tableCell, default: :tableCell
    field :content, [BlockNote.Spec.Text.t()], default: []
  end
end
