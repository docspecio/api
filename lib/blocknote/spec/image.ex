defmodule BlockNote.Spec.Image do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  @type props() :: %{:url => String.t(), :caption => String.t()}

  typedstruct enforce: true do
    field :id, String.t()
    field :type, :image, default: :image
    field :props, props()
  end
end
