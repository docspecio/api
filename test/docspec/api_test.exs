defmodule DocSpec.APITest do
  use ExUnit.Case, async: true

  use Mimic

  alias DocSpec.API
  alias DocSpec.Writer
  alias NLdoc.Conversion.Reader.Docx
  alias NLdoc.Spec.Document

  import Plug.Test
  import Plug.Conn

  doctest API

  @blocknote_document %BlockNote.Spec.Document{
    id: "abc",
    content: [
      %BlockNote.Spec.Paragraph{
        id: "xyz",
        content: [
          %BlockNote.Spec.Text{text: "Example"}
        ]
      }
    ]
  }

  @docx %Docx{
    files: %Docx.Files{
      dir: "/tmp/extracted",
      files: [],
      types: %Docx.Files.ContentTypes{}
    },
    core_properties: %{},
    document: %Docx.Files.Document{
      path: "word/document.xml",
      root: {"x", [], []},
      rels: %{}
    },
    numberings: %{},
    styles: %{}
  }

  @not_found_text """
  To use the Conversion API, upload a file.
  You can do this, for example by using the following command (replace HOSTNAME by the actual hostname):

      curl -X POST https://HOSTNAME/conversion -F "file=@<path on your filesystem to your docx>"

  The source code for this API can be found at https://github.com/docspecio/api.
  """

  describe "using a method that is not supported" do
    test "will respond with 405" do
      assert {status, headers, body} =
               conn(:get, "/conversion")
               |> API.call(API.init([]))
               |> sent_resp()

      assert 405 == status

      assert %{"code" => 405, "message" => "Method Not Allowed"} == Jason.decode!(body)

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"access-control-allow-methods", "POST"},
               {"allow", "POST"},
               {"content-type", "application/json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ] == headers
    end
  end

  describe "requesting a path that is not defined" do
    test "returns a 404" do
      assert {status, headers, body} =
               conn(:get, "/not-found")
               |> API.call(API.init([]))
               |> sent_resp()

      assert 404 == status

      assert @not_found_text == body

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "text/plain; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ] == headers
    end
  end

  describe "requesting options for /conversion" do
    test "responds with the allowed options" do
      assert {status, headers, body} =
               conn(:options, "/conversion")
               |> API.call(API.init([]))
               |> sent_resp()

      assert 204 == status

      assert "" == body

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"access-control-allow-methods", "POST"},
               {"access-control-allow-headers", "x-trace-id, x-request-id"},
               {"allow", "POST"}
             ] == headers
    end
  end

  describe "calling POST /conversion but with no file" do
    test "responds with 400" do
      assert {status, headers, body} =
               conn(:post, "/conversion")
               |> API.call(API.init([]))
               |> sent_resp()

      assert 400 == status

      assert %{"code" => 400, "message" => "No DOCX file uploaded."} == Jason.decode!(body)

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ] == headers
    end
  end

  describe "calling POST /conversion with a file but the wrong content type" do
    test "responds with 400" do
      upload = %Plug.Upload{
        path: "some/path",
        filename: "calibre-demo.json",
        content_type: "application/json"
      }

      assert {status, headers, body} =
               conn(:post, "/conversion", %{"file" => upload})
               |> API.call(API.init([]))
               |> sent_resp()

      assert 400 == status

      assert %{"code" => 400, "message" => "No DOCX file uploaded."} == Jason.decode!(body)

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ] == headers
    end
  end

  describe "calling POST /conversion with a docx file" do
    test "responds with 200 and converted document" do
      path = "/tmp/upload.docx"

      Docx
      |> expect(:open!, fn ^path -> @docx end)

      Docx
      |> expect(:convert!, fn @docx -> %Document{} end)

      Docx
      |> expect(:close!, fn @docx -> :ok end)

      Writer.BlockNote
      |> expect(:write, fn %Document{} -> {:ok, @blocknote_document} end)

      upload = %Plug.Upload{
        path: path,
        filename: "calibre-demo.docx",
        content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      }

      assert {status, headers, body} =
               conn(:post, "/conversion", %{"file" => upload})
               |> put_req_header("x-request-id", "REQUEST_ID")
               |> put_req_header("x-trace-id", "TRACE_ID")
               |> API.call(API.init([]))
               |> sent_resp()

      assert 200 == status

      assert %{
               "content" => [
                 %{
                   "content" => [%{"styles" => %{}, "text" => "Example", "type" => "text"}],
                   "id" => "xyz",
                   "type" => "paragraph"
                 }
               ],
               "id" => "abc"
             } == Jason.decode!(body)

      assert [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"x-request-id", "REQUEST_ID"},
               {"x-trace-id", "TRACE_ID"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ] == headers
    end
  end
end
