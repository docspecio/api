import { ServerBlockNoteEditor } from "npm:@blocknote/server-util@0.31.1";

const editor = ServerBlockNoteEditor.create();

async function handler(req: Request): Promise<Response> {
  if (req.method === "POST") {
    try {
    const body = await req.json();

    const html = await editor.blocksToYDoc(body, 'document-store')

    // Process the parsed JSON body here
    return new Response(html, {
        status: 200,
        headers: { "Content-Type": "application/json" },
    });
    } catch (err) {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
    });
    }
  }

  return new Response("Not Found", { status: 404 });
}

console.log("Server running at http://localhost:8000");


Deno.serve({port: 8000}, handler)
