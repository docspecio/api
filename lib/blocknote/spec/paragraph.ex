defmodule BlockNote.Spec.Paragraph do
  @doc """
  Proof of concept
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Text.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :paragraph, default: :paragraph
    field :content, content(), default: []
  end
end
