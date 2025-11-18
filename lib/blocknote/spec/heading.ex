defmodule BlockNote.Spec.Heading do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  alias BlockNote.Spec.Heading.Props

  @type content() :: BlockNote.Spec.Paragraph.content()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :heading, default: :heading
    field :content, content(), default: []
    field :props, Props.t()
  end
end
