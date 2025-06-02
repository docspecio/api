defmodule DocSpec.Writer.BlockNote do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  typedstruct module: State, enforce: true do
  end

  @type error() :: {:error, term()}

  @spec write(document :: NLdoc.Spec.Document.t()) :: {:ok, BlockNote.Spec.Document.t()} | error()
  def write(document = %NLdoc.Spec.Document{}) do
    with {:ok, {[blocknote_document], _state}} <- write_resource({document, %State{}}),
         do: {:ok, reverse(blocknote_document)}
  end

  @spec write_resource({document :: NLdoc.Spec.Document.t(), State.t()}) ::
          {:ok, {[Blocknote.Spec.Document.t()], State.t()}} | error()
  defp write_resource({document = %NLdoc.Spec.Document{}, state = %State{}}) do
    with {:ok, {contents, state}} <- write_children({document.children, state}, &write_resource/1) do
      {:ok,
       {[
          %BlockNote.Spec.Document{
            id: document.id,
            content: contents
          }
        ], state}}
    end
  end

  @spec write_resource({paragraph :: NLdoc.Spec.Paragraph.t(), State.t()}) ::
          {:ok, {[Blocknote.Spec.Paragraph.t()], State.t()}} | error()
  defp write_resource({paragraph = %NLdoc.Spec.Paragraph{}, state = %State{}}) do
    with {:ok, {contents, state}} <-
           write_children({paragraph.children, state}, &write_resource/1) do
      {:ok,
       {[
          %BlockNote.Spec.Paragraph{
            id: paragraph.id,
            content: contents
          }
        ], state}}
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.Heading.t(), State.t()}) ::
          {:ok, {[Blocknote.Spec.Heading.t()], State.t()}} | error()
  defp write_resource({resource = %NLdoc.Spec.Heading{}, state = %State{}}) do
    with {:ok, {contents, state}} <-
           write_children({resource.children, state}, &write_resource/1) do
      {:ok,
       {[
          %BlockNote.Spec.Heading{
            id: resource.id,
            content: contents,
            props: %BlockNote.Spec.Heading.Props{
              # BlockNote heading levels max out at 3
              level: min(resource.level, 3)
            }
          }
        ], state}}
    end
  end

  @spec write_resource({text :: NLdoc.Spec.Text.t(), State.t()}) ::
          {:ok, {[Blocknote.Spec.Text.t()], State.t()}} | error()
  defp write_resource({text = %NLdoc.Spec.Text{}, state = %State{}}) do
    {:ok,
     {[
        %BlockNote.Spec.Text{
          text: text.text,
          styles: convert_styling(text.styling)
        }
      ], state}}
  end

  # Fallback for unsupported stuff.
  defp write_resource({_, state}) do
    {:ok, {[], state}}
  end

  @spec convert_styling([NLdoc.Spec.text_style()]) :: BlockNote.Spec.Text.Styles.t()
  defp convert_styling(styles) do
    Enum.reduce(
      styles,
      %{},
      fn
        style, styling = %{} when style in [:italic, :bold, :underline] ->
          Map.put(styling, style, true)

        :strikethrough, styling = %{} ->
          Map.put(styling, :strike, true)

        _, styling = %{} ->
          styling
      end
    )
  end

  @spec write_children(
          {children :: [child], State.t()},
          (child, State.t() -> {:ok, {[result], State.t()}} | {:error, term})
        ) ::
          {:ok, {[result], State.t()}} | error()
        when child: var, result: var
  defp write_children({children, state = %State{}}, write_fn) do
    Enum.reduce(
      children,
      {:ok, {[], state}},
      fn child, {:ok, {contents, state}} ->
        with {:ok, {content, state}} <- write_fn.({child, state}) do
          {:ok, {content ++ contents, state}}
        end
      end
    )
  end

  defp reverse(%{content: content}) when is_list(content) do
    Enum.reduce(
      content,
      [],
      fn
        item, reversed ->
          [item | reversed]
      end
    )
  end

  defp reverse(other),
    do: other
end
