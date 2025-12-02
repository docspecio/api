defmodule BlockNote.WriterTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Mimic
  doctest BlockNote.Writer

  import NLdoc.Test.Snapshot

  alias BlockNote.Writer
  alias NLdoc.Spec.Document
  alias NLdoc.Util.Recase

  @fixtures_dir Path.join([__DIR__, "../fixtures"])
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
        |> Writer.write()

      json = blocknote |> Recase.to_camel() |> Jason.encode!() |> Jason.decode!()

      # TODO: figure out if we can validate that the result is indeed a valid BlockNote JSON object.

      snapshot_path = "BlockNote.Writer/#{filename |> Path.basename()}"
      assert_snapshot(json, snapshot_path, format: :json)
    end
  end

  describe "edge cases" do
    test "handles empty table" do
      document = %Document{
        id: "doc1",
        children: [
          %NLdoc.Spec.Table{
            id: "table1",
            children: []
          }
        ]
      }

      assert {:ok, result} = Writer.write(document)
      assert result == []
    end

    test "handles empty heading" do
      document = %Document{
        id: "doc1",
        children: [
          %NLdoc.Spec.Heading{
            id: "heading1",
            level: 1,
            children: []
          }
        ]
      }

      assert {:ok, result} = Writer.write(document)
      assert result == []
    end

    test "handles empty paragraph" do
      document = %Document{
        id: "doc1",
        children: [
          %NLdoc.Spec.Paragraph{
            id: "para1",
            children: []
          }
        ]
      }

      assert {:ok, result} = Writer.write(document)
      assert result == []
    end

    test "handles empty unordered list" do
      document = %Document{
        id: "doc1",
        children: [
          %NLdoc.Spec.UnorderedList{
            id: "list1",
            children: []
          }
        ]
      }

      assert {:ok, result} = Writer.write(document)
      assert result == []
    end

    test "handles empty ordered list" do
      document = %Document{
        id: "doc1",
        children: [
          %NLdoc.Spec.OrderedList{
            id: "list1",
            children: []
          }
        ]
      }

      assert {:ok, result} = Writer.write(document)
      assert result == []
    end

    test "handles empty preformatted" do
      document = %Document{
        id: "doc1",
        children: [
          %NLdoc.Spec.Preformatted{
            id: "pre1",
            children: []
          }
        ]
      }

      assert {:ok, result} = Writer.write(document)
      assert result == []
    end

    test "handles empty block quotation" do
      document = %Document{
        id: "doc1",
        children: [
          %NLdoc.Spec.BlockQuotation{
            id: "quote1",
            children: []
          }
        ]
      }

      assert {:ok, result} = Writer.write(document)
      assert result == []
    end

    test "handles image with missing asset" do
      document = %Document{
        id: "doc1",
        assets: [],
        children: [
          %NLdoc.Spec.Image{
            id: "img1",
            source: "#missing-asset",
            alternative_text: "Missing image"
          }
        ]
      }

      assert {:ok, result} = Writer.write(document)
      assert result == []
    end
  end
end
