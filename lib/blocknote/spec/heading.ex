defmodule BlockNote.Spec.Heading do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  alias BlockNote.Spec.Heading.Props

  @type content() :: BlockNote.Spec.Text.t()

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :heading, default: :heading
    field :content, content(), default: []
    field :props, Props.t()
  end
end
