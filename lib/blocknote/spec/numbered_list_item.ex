defmodule BlockNote.Spec.NumberedListItem do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type content() :: BlockNote.Spec.Text.t()

  @type props() :: %{optional(:start) => number()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :numberedListItem, default: :numberedListItem
    field :content, content(), default: []
    field :children, [__MODULE__.t() | BlockNote.Spec.BulletListItem.t()], default: []
    field :props, props(), default: %{}
  end
end
