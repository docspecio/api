defmodule DocSpec.Writer.BlockNoteTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Mimic
  doctest DocSpec.Writer.BlockNote

  import NLdoc.Test.Snapshot

  alias DocSpec.Writer.BlockNote
  alias NLdoc.Spec.Document
  alias NLdoc.Util.Recase

  @fixtures_dir Path.join([__DIR__, "fixtures"])
  @fixtures @fixtures_dir
            |> Path.join("**/*.json")
            |> Path.wildcard()
            |> Enum.filter(&File.regular?/1)
            # Ignore Word temporary files
            |> Enum.reject(&String.starts_with?(Path.basename(&1), "~$"))

  if @fixtures == [] do
    raise "No fixtures found in #{@fixtures_dir}"
  end

  for filename <- @fixtures do
    test "successfully converts #{filename}" do
      stub(Ecto.UUID, :generate, fn -> "00000000-0000-0000-0000-000000000000" end)
      filename = unquote(filename)

      {:ok, blocknote} =
        filename
        |> File.read!()
        |> Jason.decode!()
        |> Recase.to_snake()
        |> Document.new!()
        |> BlockNote.write()

      json = blocknote |> Recase.to_camel()

      # TODO: figure out if we can validate that the result is indeed a valid BlockNote JSON object.

      snapshot_path = "DocSpec.Writer.BlockNote/#{filename |> Path.basename()}"
      assert_snapshot(json, snapshot_path, format: :json)
    end
  end
end
