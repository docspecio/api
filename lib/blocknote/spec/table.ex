defmodule BlockNote.Spec.Table do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Table.Content.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :table, default: :table
    field :content, content(), default: []
  end
end
