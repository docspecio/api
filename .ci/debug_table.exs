doc = File.read!("test/fixtures/document-with-table.json") |> Jason.decode!()
{:ok, result} = DocSpec.Writer.BlockNote.write(doc)
table = hd(result)
IO.puts("Number of rows: #{length(table.content.rows)}")
Enum.with_index(table.content.rows) |> Enum.each(fn {row, idx} ->
  IO.puts("Row #{idx}: #{length(row.cells)} cells")
  Enum.each(row.cells, fn cell ->
    IO.puts("  colspan: #{cell.props[:colspan]}, rowspan: #{cell.props[:rowspan]}")
  end)
end)
