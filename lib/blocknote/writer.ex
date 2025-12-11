defmodule BlockNote.Writer do
  @moduledoc """
  Writer for BlockNote structure.
  """

  use TypedStruct

  alias BlockNote.Writer.Color
  alias DocSpec.Util.Color.RGB

  defmodule State do
    @moduledoc """
    Format of state modified during converting.
    """

    typedstruct enforce: true do
      field :assets, [NLdoc.Spec.Asset.t()], default: []
      field :parent_list_type, :bullet | :numbered | nil, default: nil
      field :parent_list_start, number() | nil, default: nil
      field :extracted_blocks, [BlockNote.Spec.Document.content()], default: []
    end
  end

  defmodule Context do
    @moduledoc """
    Context for conversion that is only relevant to children and not to be passed back.
    """

    typedstruct enforce: true do
      field :inline_mode?, boolean(), default: false
    end
  end

  @type error() :: {:error, term()}

  @uri_color "https://docspec.org/ns/style#color"
  @uri_highlight_color "https://docspec.org/ns/style#highlightColor"
  @uri_text_alignment "https://docspec.org/ns/style#textAlignment"

  @max_heading_level 6

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

  defp write_resource({%mod{children: []}, state = %State{}, _context})
       when mod in [NLdoc.Spec.Table, NLdoc.Spec.UnorderedList, NLdoc.Spec.OrderedList],
       do: {:ok, {[], state}} |> add_extracted_blocks()

  @spec write_resource({resource :: NLdoc.Spec.Paragraph.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Paragraph.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.Paragraph{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.Paragraph{
            id: resource.id,
            content: contents,
            props: set_text_alignment(%{}, resource.descriptors)
          }
        ], state}}
      |> add_extracted_blocks()
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
    |> add_extracted_blocks()
  end

  @spec write_resource({resource :: NLdoc.Spec.OrderedList.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.NumberedListItem.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.OrderedList{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    {resource.children,
     %State{state | parent_list_type: :numbered, parent_list_start: resource.start}, context}
    |> write_children(&write_resource/1)
    |> add_extracted_blocks()
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

    with {:ok, {bn_texts, state = %State{}}} <-
           write_children({texts, state, context}, &write_resource/1),
         {:ok, {nested_items, state = %State{}}} <-
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
            children: nested_items,
            props:
              if is_nil(state.parent_list_start) do
                %{}
              else
                %{start: state.parent_list_start}
              end
          }
        end

      {:ok, {[item], %State{state | parent_list_start: nil}}}
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
      |> add_extracted_blocks()
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
      |> add_extracted_blocks()
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
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.Heading{
            id: resource.id,
            content: contents,
            props:
              %BlockNote.Spec.Heading.Props{
                level: min(resource.level, @max_heading_level),
                text_alignment: "left"
              }
              |> set_text_alignment(resource.descriptors)
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.Preformatted.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.CodeBlock.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.Preformatted{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.CodeBlock{
            id: resource.id,
            content: contents,
            props: set_text_alignment(%{}, resource.descriptors)
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.BlockQuotation.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Quote.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.BlockQuotation{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
    with {:ok, {contents, state}} <-
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
             &write_resource/1
           ) do
      {:ok,
       {[
          %BlockNote.Spec.Quote{
            id: resource.id,
            content: contents,
            props: set_text_alignment(%{}, resource.descriptors)
          }
        ], state}}
      |> add_extracted_blocks()
    end
  end

  @spec write_resource({resource :: NLdoc.Spec.Table.t(), State.t(), Context.t()}) ::
          {:ok, {[BlockNote.Spec.Table.t()], State.t()}} | error()
  defp write_resource(
         {resource = %NLdoc.Spec.Table{}, state = %State{},
          context = %Context{inline_mode?: false}}
       ) do
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
      |> add_extracted_blocks()
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
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
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
           write_text_children(
             {resource.children, state, %Context{} = %{context | inline_mode?: true}},
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
          styles: convert_styling(text.styling, text.descriptors)
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
  defp write_resource({_, state, _context}), do: {:ok, {[], state}}

  @spec set_text_alignment(props, [NLdoc.Spec.descriptor()]) :: props
        when props: map()
  defp set_text_alignment(props, descriptors) when is_map(props) and is_list(descriptors) do
    descriptors
    |> Enum.reduce(
      props,
      fn
        %NLdoc.Spec.StringDescriptor{uri: @uri_text_alignment, value: value}, props
        when value in ["right", "center", "justify"] ->
          Map.put(props, :text_alignment, value)

        _, props ->
          props
      end
    )
  end

  # Normalizes table rows by ensuring all rows have equal total colspan
  # and setting all rowspan values to 1. BlockNote's table implementation
  # doesn't properly support rowspan (cells spanning multiple rows), which
  # can cause rendering issues or validation errors. By setting all rowspan
  # to 1, we ensure tables render correctly even if the source document
  # specified rowspan values.
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
    max_colspan =
      case row_colspans do
        [] -> 0
        list -> Enum.max(list)
      end

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

  @spec convert_styling(
          styles :: [NLdoc.Spec.text_style()],
          descriptors :: [NLdoc.Spec.descriptor()]
        ) :: BlockNote.Spec.Text.Styles.t()
  defp convert_styling(styles, descriptors) do
    Enum.reduce(
      styles ++ descriptors,
      %{},
      fn
        style, styling = %{} when style in [:italic, :bold, :underline] ->
          Map.put(styling, style, true)

        :strikethrough, styling = %{} ->
          Map.put(styling, :strike, true)

        %NLdoc.Spec.StringDescriptor{
          uri: @uri_color,
          value: color
        },
        styling = %{} ->
          color_name = nearest_color(:text, color)

          if is_nil(color_name) do
            styling
          else
            Map.put(styling, :text_color, color_name)
          end

        %NLdoc.Spec.StringDescriptor{
          uri: @uri_highlight_color,
          value: color
        },
        styling = %{} ->
          color_name = nearest_color(:background, color)

          if is_nil(color_name) do
            styling
          else
            Map.put(styling, :background_color, color_name)
          end

        _, styling = %{} ->
          styling
      end
    )
  end

  @spec nearest_color(type :: :text | :background, color :: String.t()) :: Color.name() | nil
  defp nearest_color(type, color)
       when is_binary(color)
       when type == :background or type == :text do
    with {:ok, rgb} <- RGB.Hex.to_rgb(color),
         false <- rgb == {0, 0, 0},
         {:ok, name} <- Color.nearest(type, rgb) do
      name
    else
      _ -> nil
    end
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

  @spec write_text_children(
          {children :: [child], State.t(), Context.t()},
          ({child, State.t(), Context.t()} -> {:ok, {[result], State.t()}} | error())
        ) ::
          {:ok, {[result], State.t()}} | error()
        when child: var, result: var
  defp write_text_children({children, state = %State{}, context = %Context{}}, write_fn) do
    Enum.reduce(
      children,
      {:ok, {[], state}},
      fn
        %NLdoc.Spec.Paragraph{children: children}, {:ok, {contents, state}} ->
          with {:ok, {content, state}} <-
                 write_children(
                   {children, state, %Context{} = %{context | inline_mode?: true}},
                   write_fn
                 ) do
            {:ok, {content ++ contents, state}}
          end

        # Handle inline content (Text, Link) - keep in contents
        resource = %mod{}, {:ok, {contents, state}}
        when mod in [NLdoc.Spec.Text, NLdoc.Spec.Link] ->
          with {:ok, {inline_content, state}} <-
                 write_resource({resource, state, %Context{} = %{context | inline_mode?: true}}) do
            {:ok, {inline_content ++ contents, state}}
          end

        # Handle block-level elements - extract as separate blocks
        resource, {:ok, {contents, state}} ->
          with {:ok, {block_contents, state}} <-
                 write_resource({resource, state, %Context{} = %{context | inline_mode?: false}}) do
            {:ok,
             {contents,
              %State{} = %{
                state
                | extracted_blocks: block_contents ++ state.extracted_blocks
              }}}
          end
      end
    )
  end

  @spec add_extracted_blocks({[BlockNote.Spec.Document.content()], State.t()}) ::
          {[BlockNote.Spec.Document.content()], State.t()}
  @spec add_extracted_blocks({:ok, {[BlockNote.Spec.Document.content()], State.t()}}) ::
          {:ok, {[BlockNote.Spec.Document.content()], State.t()}}
  defp add_extracted_blocks({blocks, state = %State{}}) when is_list(blocks),
    do: {state.extracted_blocks ++ blocks, %State{} = %{state | extracted_blocks: []}}

  defp add_extracted_blocks({:ok, {blocks, state = %State{}}}) when is_list(blocks),
    do: {:ok, add_extracted_blocks({blocks, state})}

  @spec reverse(content) :: content when content: term()
  defp reverse(content) when is_list(content),
    do:
      content
      |> Enum.map(&reverse/1)
      |> Enum.reverse()

  defp reverse(resource = %{content: content}) when is_list(content) or is_map(content),
    do: Map.put(resource, :content, reverse(content))

  defp reverse(resource = %{rows: rows}) when is_list(rows),
    do: Map.put(resource, :rows, reverse(rows))

  defp reverse(resource = %{cells: cells}) when is_list(cells),
    do: Map.put(resource, :cells, reverse(cells))

  defp reverse(other),
    do: other
end
