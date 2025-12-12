defmodule BlockNote.Spec.Document do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type content() ::
          BlockNote.Spec.BulletListItem.t()
          | BlockNote.Spec.CodeBlock.t()
          | BlockNote.Spec.Heading.t()
          | BlockNote.Spec.Image.t()
          | BlockNote.Spec.NumberedListItem.t()
          | BlockNote.Spec.Paragraph.t()
          | BlockNote.Spec.Quote.t()
          | BlockNote.Spec.Table.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :content, [content()], default: []
  end
end
