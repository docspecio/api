defmodule BlockNote.Spec.Quote do
  @moduledoc """
  Quote Block.

  See: https://www.blocknotejs.org/docs/features/blocks/typography#quote
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Paragraph.content()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :quote, default: :quote
    field :content, content(), default: []
  end
end
