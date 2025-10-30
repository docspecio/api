defmodule BlockNote.Spec.Document do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Paragraph.t() | BlockNote.Spec.Heading.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :content, content(), default: []
  end
end
