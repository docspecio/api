defmodule BlockNote.Spec.BulletListItem do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Text.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :bulletListItem, default: :bulletListItem
    field :content, content(), default: []
    field :children, [__MODULE__.t()], default: []
  end
end
