defmodule BlockNote.Spec.Table.Content do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type row() :: %{cells: [[BlockNote.Spec.Text.t()]]}

  typedstruct enforce: true do
    field :type, :tableContent, default: :tableContent
    field :rows, [row()], default: []
  end
end
