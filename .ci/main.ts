import { ServerBlockNoteEditor } from "@blocknote/server-util";

const editor = ServerBlockNoteEditor.create();

let exitCode = 0;

for (const path of Deno.args) {
  const text = await Deno.readTextFile(path);
  const json = JSON.parse(text);

  try {
    await editor.blocksToHTMLLossy(json);
    await editor.blocksToFullHTML(json);
    await editor.blocksToMarkdownLossy(json);
    await editor.blocksToYDoc(json);

    console.log(`✅️ ${path}`);
  } catch (e) {
    console.error(`❌ ${path}`);
    console.error('')
    console.error(e)
    console.error('')

    exitCode = 1;
  }
}

Deno.exit(exitCode);
