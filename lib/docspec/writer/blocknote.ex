defmodule DocSpec.Writer.BlockNote do
  @moduledoc """
  Proof of concept
  """

  use TypedStruct

  defmodule State do
    @moduledoc """
    Format of state modified during converting.
    """

    typedstruct enforce: true do
      field :assets, [NLdoc.Spec.Asset.t()], default: []
      field :parent_list_type, :bullet | :numbered | nil, default: nil
    end
  end

  defmodule Context do
    @moduledoc """
    Context for conversion that is only relevant to children and not to be passed back.
    """

    typedstruct enforce: true do
      field :inline_mode?, boolean(), default: false
    end

    @spec enable_inline_mode(context :: t()) :: t()
    def enable_inline_mode(context = %__MODULE__{}),
      do: %__MODULE__{context | inline_mode?: true}
  end

  @type error() :: {:error, term()}

  @spec write(document :: NLdoc.Spec.Document.t()) ::
          {:ok, [BlockNote.Spec.Document.content()]} | error()
  def write(document = %NLdoc.Spec.Document{}) do
    with {:ok, {[blocknote_document], _state}} <-
           write_resource({document, %State{assets: document.assets}, %Context{}}),
         do: {:ok, reverse(blocknote_document.content)}
  end

  @spec write_resource({document :: NLdoc.Spec.Document.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Document.t()], State.t()}} | error()
  defp write_resource(
         {document = %NLdoc.Spec.Document{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_children({document.children, state, context}, &write_resource/1) do
      {:ok,
       {[
          %BlockNote.Spec.Document{
            id: document.id,
            content: contents
          }
        ], state}}
    end
  end

  defp write_resource({%NLdoc.Spec.Table{children: []}, state = %State{}, _context}),
    do: {:ok, {[], state}}

  defp write_resource({%NLdoc.Spec.Heading{children: []}, state = %State{}, _context}),
    do: {:ok, {[], state}}

  defp write_resource({%NLdoc.Spec.Paragraph{children: []}, state = %State{}, _context}),
    do: {:ok, {[], state}}

  defp write_resource({%NLdoc.Spec.UnorderedList{children: []}, state = %State{}, _context}),
    do: {:ok, {[], state}}

  defp write_resource({%NLdoc.Spec.OrderedList{children: []}, state = %State{}, _context}),
    do: {:ok, {[], state}}

  defp write_resource({%NLdoc.Spec.Preformatted{children: []}, state = %State{}, _context}),
    do: {:ok, {[], state}}

  defp write_resource({%NLdoc.Spec.BlockQuotation{children: []}, state = %State{}, _context}),
    do: {:ok, {[], state}}

  @spec write_resource({paragraph :: NLdoc.Spec.Paragraph.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Paragraph.t()], State.t()}} | error()
  defp write_resource(
         {paragraph = %NLdoc.Spec.Paragraph{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_children(
             {paragraph.children, state, Context.enable_inline_mode(context)},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.Paragraph{
            id: paragraph.id,
            content: contents
          }
        ], state}}
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.UnorderedList.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.BulletListItem.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.UnorderedList{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    {resource.children, %State{state | parent_list_type: :bullet}, context}
    |> write_children(&write_resource/1)
  end

  @spec write_resource({resource :: NLdoc.Spec.OrderedList.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.NumberedListItem.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.OrderedList{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    {resource.children, %State{state | parent_list_type: :numbered}, context}
    |> write_children(&write_resource/1)
  end

  @spec write_resource({resource :: NLdoc.Spec.ListItem.t(), State.t(), Context.t()}) ::
          {:ok,
           {[BlockNote.Spec.BulletListItem.t() | BlockNote.Spec.NumberedListItem.t()], State.t()}}
          | error()
  defp write_resource(
         {resource = %NLdoc.Spec.ListItem{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    texts =
      resource.children
      |> Enum.filter(fn %{type: type} -> type == NLdoc.Spec.Paragraph.resource_type() end)
      |> NLdoc.Spec.Content.text()

    lists =
      resource.children
      |> Enum.filter(fn %{type: type} ->
        type in [NLdoc.Spec.OrderedList.resource_type(), NLdoc.Spec.UnorderedList.resource_type()]
      end)

    with {:ok, {bn_texts, state}} <- write_children({texts, state, context}, &write_resource/1),
         {:ok, {nested_items, state}} <-
           write_children({lists, state, context}, &write_resource/1) do
      item =
        if state.parent_list_type == :bullet do
          %BlockNote.Spec.BulletListItem{
            id: resource.id,
            content: bn_texts,
            children: nested_items
          }
        else
          %BlockNote.Spec.NumberedListItem{
            id: resource.id,
            content: bn_texts,
            children: nested_items
          }
        end

      {:ok, {[item], state}}
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.Image.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Image.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.Image{}, state = %State{},
          _context = %Context{inline_mode?: false}}
       ) do
    asset =
      Enum.find(state.assets, fn %NLdoc.Spec.Asset{id: id} -> "#" <> id == resource.source end)

    if is_nil(asset) do
      {:ok, {[], state}}
    else
      {:ok,
       {[
          %BlockNote.Spec.Image{
            id: resource.id,
            props: %{
              url: NLdoc.Spec.Asset.to_base64(asset),
              caption: resource.alternative_text || ""
            }
          }
        ], state}}
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.Heading.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Heading.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.Heading{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_children(
             {resource.children, state, Context.enable_inline_mode(context)},
             &write_resource/1
           ) do
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

  @spec write_resource({resource :: NLdoc.Spec.Preformatted.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.CodeBlock.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.Preformatted{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_children(
             {resource.children, state, Context.enable_inline_mode(context)},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.CodeBlock{
            id: resource.id,
            content: contents
          }
        ], state}}
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.BlockQuotation.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Quote.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.BlockQuotation{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_children(
             {resource.children, state, Context.enable_inline_mode(context)},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.Quote{
            id: resource.id,
            content: contents
          }
        ], state}}
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.Table.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Table.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.Table{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    # Skip empty tables - BlockNote requires at least one row
    if resource.children == [] do
      {:ok, {[], state}}
    else
      with {:ok, {rows, state}} <-
             write_children({resource.children, state, context}, &write_resource/1) do
        # Normalize table structure to handle rowspan/colspan correctly
        normalized_rows = normalize_table_rows(rows)

        {:ok,
         {[
            %BlockNote.Spec.Table{
              id: resource.id,
              content: %BlockNote.Spec.Table.Content{rows: normalized_rows}
            }
          ], state}}
      end
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.TableRow.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Table.Content.row()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.TableRow{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {cells, state}} <-
           write_children({resource.children, state, context}, &write_resource/1) do
      {:ok, {[%{cells: cells}], state}}
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.TableHeader.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Table.Cell.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.TableHeader{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {bn_texts, state}} <-
           write_children(
             {resource.children, state, Context.enable_inline_mode(context)},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.Table.Cell{
            id: resource.id,
            content: bn_texts,
            props: %{
              colspan: resource.colspan,
              rowspan: resource.rowspan
            }
          }
        ], state}}
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.TableCell.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Table.Cell.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.TableCell{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {bn_texts, state}} <-
           write_children(
             {resource.children, state, Context.enable_inline_mode(context)},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.Table.Cell{
            id: resource.id,
            content: bn_texts,
            props: %{
              colspan: resource.colspan,
              rowspan: resource.rowspan
            }
          }
        ], state}}
    end
  end

  @spec write_resource({text :: NLdoc.Spec.Text.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Text.t()], State.t()}} | error()
  defp write_resource({text = %NLdoc.Spec.Text{}, state = %State{}, _context = %Context{}}) do
    {:ok,
     {[
        %BlockNote.Spec.Text{
          text: text.text,
          styles: convert_styling(text.styling)
        }
      ], state}}
  end

  @spec write_resource({resource :: NLdoc.Spec.Link.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Link.t()], State.t()}} | error()
  defp write_resource({resource = %NLdoc.Spec.Link{}, state = %State{}, _context = %Context{}}) do
    {:ok,
     {[
        %BlockNote.Spec.Link{
          id: resource.id,
          content: [
            %BlockNote.Spec.Text{
              text: resource.text
            }
          ],
          href: resource.uri
        }
      ], state}}
  end

  defp write_resource(
         {%{children: children}, state = %State{}, context = %Context{inline_mode?: true}}
       ),
       do: write_children({children, state, context}, &write_resource/1)

  # Fallback for unsupported stuff.
  defp write_resource({_, state, _context}) do
    {:ok, {[], state}}
  end

  # Normalizes table rows by ensuring all rows have equal total colspan
  # and setting all rowspan values to 1 to avoid BlockNote occupancy grid issues
  @spec normalize_table_rows([BlockNote.Spec.Table.Content.row()]) :: [
          BlockNote.Spec.Table.Content.row()
        ]
  defp normalize_table_rows(rows) do
    # Calculate total colspan for each row
    row_colspans =
      Enum.map(rows, fn row ->
        Enum.reduce(row.cells, 0, fn cell, acc ->
          acc + (cell.props[:colspan] || 1)
        end)
      end)

    # Find max colspan across all rows
    max_colspan = Enum.max(row_colspans, fn -> 0 end)

    # Adjust each row to have max_colspan and set all rowspan to 1
    Enum.zip(rows, row_colspans)
    |> Enum.map(fn {row, current_colspan} ->
      colspan_diff = max_colspan - current_colspan

      # Normalize cells: fix colspan on last cell and set rowspan to 1
      normalized_cells =
        if colspan_diff > 0 and row.cells != [] do
          [last_cell | rest_cells] = Enum.reverse(row.cells)
          current_last_colspan = last_cell.props[:colspan] || 1

          updated_last_cell =
            put_in(last_cell.props[:colspan], current_last_colspan + colspan_diff)

          Enum.reverse([updated_last_cell | rest_cells])
        else
          row.cells
        end

      # Set all rowspan values to 1 to avoid occupancy grid conflicts
      normalized_rowspan_cells =
        Enum.map(normalized_cells, fn cell ->
          put_in(cell.props[:rowspan], 1)
        end)

      %{cells: normalized_rowspan_cells}
    end)
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
          {children :: [child], State.t(), Context.t()},
          ({child, State.t(), Context.t()} -> {:ok, {[result], State.t()}} | error())
        ) ::
          {:ok, {[result], State.t()}} | error()
        when child: var, result: var
  defp write_children({children, state = %State{}, context = %Context{}}, write_fn) do
    Enum.reduce(
      children,
      {:ok, {[], state}},
      fn child, {:ok, {contents, state}} ->
        with {:ok, {content, state}} <- write_fn.({child, state, context}) do
          {:ok, {content ++ contents, state}}
        end
      end
    )
  end

  defp reverse(content) when is_list(content) do
    content
    |> Enum.map(&reverse/1)
    |> Enum.reverse()
  end

  defp reverse(resource = %{content: content}) when is_list(content) do
    Map.put(resource, :content, reverse(content))
  end

  defp reverse(resource = %{content: content}) when is_map(content) do
    Map.put(resource, :content, reverse(content))
  end

  defp reverse(resource = %{rows: rows}) when is_list(rows) do
    Map.put(resource, :rows, reverse(rows))
  end

  defp reverse(resource = %{cells: cells}) when is_list(cells) do
    Map.put(resource, :cells, reverse(cells))
  end

  defp reverse(other),
    do: other
end
