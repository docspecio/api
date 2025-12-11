defmodule BlockNote.Spec.Paragraph do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Text.t() | BlockNote.Spec.Link.t()
  @type props() :: %{optional(:text_alignment) => String.t()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :paragraph, default: :paragraph
    field :content, [content()], default: []
    field :props, props(), default: %{}
  end
end
