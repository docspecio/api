defmodule DocSpec.API.Controller.ConversionTest do
  use ExUnit.Case, async: true
  use Mimic

  import Plug.Test
  import Plug.Conn

  alias DocSpec.API
  alias DocSpec.Core.BlockNote.Writer, as: BlockNoteWriter
  alias DocSpec.Core.DOCX.Reader, as: DOCXReader
  alias DocSpec.Spec.DocumentSpecification

  @docx_content_type "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  @blocknote_accept "application/vnd.docspec.blocknote+json"
  @fixture_path Path.expand("../../../support/fixtures/simple.docx", __DIR__)

  @blocknote_document [
    %DocSpec.Core.BlockNote.Spec.Paragraph{
      id: "block-1",
      content: [%DocSpec.Core.BlockNote.Spec.Text{text: "Example"}]
    }
  ]

  describe "POST /conversion raw DOCX upload contract" do
    @tag :success
    test "raw DOCX upload returns 200 with BlockNote JSON" do
      docx_reader = :mock_docx_reader

      document_spec = %DocumentSpecification{
        document: %DocSpec.Spec.Document{id: "doc-1", children: []}
      }

      DOCXReader
      |> expect(:open!, fn _path -> docx_reader end)

      DOCXReader
      |> expect(:convert!, fn ^docx_reader -> document_spec end)

      DOCXReader
      |> expect(:close!, fn ^docx_reader -> :ok end)

      BlockNoteWriter
      |> expect(:write, fn ^document_spec -> {:ok, @blocknote_document} end)

      {status, headers, body} =
        @fixture_path
        |> File.read!()
        |> raw_request()
        |> put_req_header("content-type", @docx_content_type)
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 200

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "#{@blocknote_accept}; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == [
               %{
                 "content" => [%{"text" => "Example", "type" => "text"}],
                 "id" => "block-1",
                 "type" => "paragraph"
               }
             ]
    end

    @tag :missing_accept
    test "missing Accept header returns 200 with BlockNote JSON" do
      docx_reader = :mock_docx_reader

      document_spec = %DocumentSpecification{
        document: %DocSpec.Spec.Document{id: "doc-3", children: []}
      }

      DOCXReader
      |> expect(:open!, fn _path -> docx_reader end)

      DOCXReader
      |> expect(:convert!, fn ^docx_reader -> document_spec end)

      DOCXReader
      |> expect(:close!, fn ^docx_reader -> :ok end)

      BlockNoteWriter
      |> expect(:write, fn ^document_spec -> {:ok, @blocknote_document} end)

      {status, headers, body} =
        @fixture_path
        |> File.read!()
        |> raw_request()
        |> put_req_header("content-type", @docx_content_type)
        |> request()

      assert status == 200

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "#{@blocknote_accept}; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == [
               %{
                 "content" => [%{"text" => "Example", "type" => "text"}],
                 "id" => "block-1",
                 "type" => "paragraph"
               }
             ]
    end

    @tag :wrong_accept
    test "wrong Accept header returns 406 with RFC 7807" do
      {status, headers, body} =
        @fixture_path
        |> File.read!()
        |> raw_request()
        |> put_req_header("content-type", @docx_content_type)
        |> put_req_header("accept", "text/html")
        |> request()

      assert status == 406

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Not Acceptable",
               "status" => 406,
               "detail" =>
                 "Accept header must include application/vnd.docspec.blocknote+json or application/vnd.blocknote+json"
             }
    end

    @tag :star_accept
    test "Accept: */* returns 200 with BlockNote JSON" do
      docx_reader = :mock_docx_reader

      document_spec = %DocumentSpecification{
        document: %DocSpec.Spec.Document{id: "doc-5", children: []}
      }

      DOCXReader
      |> expect(:open!, fn _path -> docx_reader end)

      DOCXReader
      |> expect(:convert!, fn ^docx_reader -> document_spec end)

      DOCXReader
      |> expect(:close!, fn ^docx_reader -> :ok end)

      BlockNoteWriter
      |> expect(:write, fn ^document_spec -> {:ok, @blocknote_document} end)

      {status, headers, body} =
        @fixture_path
        |> File.read!()
        |> raw_request()
        |> put_req_header("content-type", @docx_content_type)
        |> put_req_header("accept", "*/*")
        |> request()

      assert status == 200

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "#{@blocknote_accept}; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == [
               %{
                 "content" => [%{"text" => "Example", "type" => "text"}],
                 "id" => "block-1",
                 "type" => "paragraph"
               }
             ]
    end

    @tag :content_type_params
    test "Content-Type with params is normalized and returns 200" do
      docx_reader = :mock_docx_reader

      document_spec = %DocumentSpecification{
        document: %DocSpec.Spec.Document{id: "doc-6", children: []}
      }

      DOCXReader
      |> expect(:open!, fn _path -> docx_reader end)

      DOCXReader
      |> expect(:convert!, fn ^docx_reader -> document_spec end)

      DOCXReader
      |> expect(:close!, fn ^docx_reader -> :ok end)

      BlockNoteWriter
      |> expect(:write, fn ^document_spec -> {:ok, @blocknote_document} end)

      {status, headers, body} =
        @fixture_path
        |> File.read!()
        |> raw_request()
        |> put_req_header("content-type", "#{@docx_content_type}; charset=binary")
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 200

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "#{@blocknote_accept}; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == [
               %{
                 "content" => [%{"text" => "Example", "type" => "text"}],
                 "id" => "block-1",
                 "type" => "paragraph"
               }
             ]
    end

    @tag :missing_content_type
    test "missing Content-Type defaults to DOCX and returns 200 with BlockNote JSON" do
      docx_reader = :mock_docx_reader

      document_spec = %DocumentSpecification{
        document: %DocSpec.Spec.Document{id: "doc-4", children: []}
      }

      DOCXReader
      |> expect(:open!, fn _path -> docx_reader end)

      DOCXReader
      |> expect(:convert!, fn ^docx_reader -> document_spec end)

      DOCXReader
      |> expect(:close!, fn ^docx_reader -> :ok end)

      BlockNoteWriter
      |> expect(:write, fn ^document_spec -> {:ok, @blocknote_document} end)

      {status, headers, body} =
        @fixture_path
        |> File.read!()
        |> raw_request()
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 200

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "#{@blocknote_accept}; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == [
               %{
                 "content" => [%{"text" => "Example", "type" => "text"}],
                 "id" => "block-1",
                 "type" => "paragraph"
               }
             ]
    end

    @tag :wrong_content_type
    test "wrong Content-Type returns 415 with RFC 7807" do
      {status, headers, body} =
        @fixture_path
        |> File.read!()
        |> raw_request()
        |> put_req_header("content-type", "text/plain")
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 415

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Unsupported Media Type",
               "status" => 415,
               "detail" => "Content-Type must be #{@docx_content_type}"
             }
    end

    @tag :multipart
    test "multipart request returns 415 with RFC 7807" do
      {status, headers, body} =
        ~S(--boundary\r\ncontent-disposition: form-data; name="file"; filename="simple.docx"\r\n\r\nnot-a-docx\r\n--boundary--\r\n)
        |> raw_request()
        |> put_req_header("content-type", "multipart/form-data; boundary=boundary")
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 415

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Unsupported Media Type",
               "status" => 415,
               "detail" => "Multipart uploads are not supported. Send raw binary body."
             }
    end

    @tag :empty_body
    test "empty body returns 400 with RFC 7807" do
      {status, headers, body} =
        <<>>
        |> raw_request()
        |> put_req_header("content-type", @docx_content_type)
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 400

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Bad Request",
               "status" => 400,
               "detail" => "Request body is empty"
             }
    end

    @tag :malformed_docx
    test "malformed DOCX returns 422 with RFC 7807" do
      {status, headers, body} =
        "this-is-not-a-valid-docx"
        |> raw_request()
        |> put_req_header("content-type", @docx_content_type)
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 422

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Unprocessable Content",
               "status" => 422,
               "detail" => "Document could not be parsed as valid DOCX"
             }
    end

    @tag :internal_error
    test "internal conversion error returns 500 with RFC 7807" do
      docx_reader = :mock_docx_reader

      document_spec = %DocumentSpecification{
        document: %DocSpec.Spec.Document{id: "doc-2", children: []}
      }

      DOCXReader
      |> expect(:open!, fn _path -> docx_reader end)

      DOCXReader
      |> expect(:convert!, fn ^docx_reader -> document_spec end)

      DOCXReader
      |> expect(:close!, fn ^docx_reader -> :ok end)

      BlockNoteWriter
      |> expect(:write, fn ^document_spec -> raise RuntimeError, "boom" end)

      {status, headers, body} =
        @fixture_path
        |> File.read!()
        |> raw_request()
        |> put_req_header("content-type", @docx_content_type)
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 500

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Internal Server Error",
               "status" => 500,
               "detail" => "An unexpected error occurred during conversion"
             }

      refute String.contains?(body, "RuntimeError")
      refute String.contains?(body, "boom")
      refute String.contains?(body, "stack")
    end

    @tag :payload_too_large
    test "body exceeding size limit returns 413 with RFC 7807" do
      {status, headers, body} =
        String.duplicate("A", 2048)
        |> raw_request()
        |> put_req_header("content-type", @docx_content_type)
        |> put_req_header("accept", @blocknote_accept)
        |> request()

      assert status == 413

      assert headers == [
               {"cache-control", "max-age=0, private, must-revalidate"},
               {"access-control-allow-origin", "*"},
               {"content-type", "application/problem+json; charset=utf-8"},
               {"access-control-expose-headers", "x-trace-id, x-request-id"}
             ]

      assert Jason.decode!(body) == %{
               "type" => "about:blank",
               "title" => "Payload Too Large",
               "status" => 413,
               "detail" => "Request body exceeds maximum size"
             }
    end
  end

  defp raw_request(body),
    do: conn(:post, "/conversion", body)

  defp request(conn),
    do:
      conn
      |> API.call(API.init([]))
      |> sent_resp()
end
