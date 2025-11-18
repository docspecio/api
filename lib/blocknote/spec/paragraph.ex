defmodule BlockNote.Spec.Paragraph do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Text.t() | BlockNote.Spec.Link.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :paragraph, default: :paragraph
    field :content, content(), default: []
  end
end
