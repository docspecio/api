import { ServerBlockNoteEditor } from "@blocknote/server-util";
import * as Y from 'yjs';

import express, { Request, Response } from 'express';
import cors from 'cors';

const server = ServerBlockNoteEditor.create()

const app = express();
const port = process.env.PORT || 9871;

app.use(cors({
  origin: '*',
  methods: ['POST','OPTIONS'],
  allowedHeaders: ['Content-Type','X-Requested-With','Accept'],
}));

app.use(express.json());

app.post('/', async (req: Request, res: Response) => {
  const ydoc = await server.blocksToYDoc(req.body, 'document-store')
  const update = Y.encodeStateAsUpdate(ydoc);
  const base64 = Buffer.from(update).toString("base64");

  res.send(base64)
});

app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});
