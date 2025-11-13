defmodule BlockNote.Spec.CodeBlock do
  @moduledoc """
  BlockNote Code Block

  See: https://www.blocknotejs.org/docs/features/blocks/code-blocks
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Paragraph.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :codeBlock, default: :codeBlock
    field :children, content(), default: []
  end
end
