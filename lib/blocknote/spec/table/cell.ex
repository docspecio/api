defmodule BlockNote.Spec.Table.Cell do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type props() :: %{optional(:colspan) => integer(), optional(:rowspan) => integer()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :tableCell, default: :tableCell
    field :content, [BlockNote.Spec.Text.t()], default: []
    field :props, props(), default: %{}
  end
end
