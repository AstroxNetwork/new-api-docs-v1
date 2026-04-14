import { createOpenAPI } from 'fumadocs-openapi/server';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';

const DEFAULT_OPENAPI_SERVER_URL = 'https://llm.holycrab.ai';

function applyGlobalServer(doc: unknown): unknown {
  if (!doc || typeof doc !== 'object') return doc;

  const serverUrl =
    process.env.OPENAPI_SERVER_URL?.trim() || DEFAULT_OPENAPI_SERVER_URL;

  return {
    ...(doc as Record<string, unknown>),
    // Force a global server to keep all cURL examples consistent.
    servers: [{ url: serverUrl }],
  };
}

async function walkJsonFiles(dir: string): Promise<string[]> {
  const out: string[] = [];
  async function walk(current: string) {
    let entries: Array<{ name: string; isDirectory: boolean; isFile: boolean }>;
    try {
      entries = (await readdir(current, { withFileTypes: true })) as any;
    } catch {
      return;
    }
    for (const e of entries as any) {
      const full = path.join(current, e.name);
      if (e.isDirectory()) {
        await walk(full);
      } else if (e.isFile() && e.name.toLowerCase().endsWith('.json')) {
        const rel = path.relative(process.cwd(), full);
        out.push(rel.split(path.sep).join('/'));
      }
    }
  }
  await walk(dir);
  return out;
}

export const openapi = createOpenAPI({
  // Keep proxy configurable. When set, API try-it calls go through this route.
  // Leave empty to let docs use upstream server URL directly.
  ...(process.env.OPENAPI_PROXY_URL?.trim()
    ? { proxyUrl: process.env.OPENAPI_PROXY_URL.trim() }
    : {}),
  // Always load generated per-endpoint OpenAPI files (clean single source of truth)
  async input() {
    const files = await walkJsonFiles('./openapi/generated');
    if (files.length === 0) {
      throw new Error(
        'No generated OpenAPI files found in ./openapi/generated. Run: bun run generate:openapi'
      );
    }
    const entries = await Promise.all(
      files.map(async (p) => {
        const raw = await readFile(p, 'utf8');
        return [p, applyGlobalServer(JSON.parse(raw))] as const;
      })
    );
    return Object.fromEntries(entries);
  },
});
