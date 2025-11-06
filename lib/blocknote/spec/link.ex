defmodule BlockNote.Spec.Link do
  @moduledoc """
  Representation of Link in BlockNote.
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Text.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :link, default: :link
    field :content, content(), default: []
    field :href, String.t()
  end
end
