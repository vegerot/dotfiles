// A stdio MCP placeholder for optional programs that are not installed.
// Run with Bun (already used by the Chrome MCP servers); no packages required.
import { createInterface } from "node:readline";

const input = createInterface({ input: process.stdin });
for await (const line of input) {
  // Input comes from the MCP client, which sends one JSON-RPC message per line.
  const request = JSON.parse(line);
  if (!("id" in request)) continue; // Notifications have no response.

  let response;
  switch (request.method) {
    case "initialize":
      response = {
        result: {
          protocolVersion: "2025-11-25",
          capabilities: { tools: {} },
          serverInfo: { name: "empty-mcp", version: "1.0.0" },
        },
      };
      break;
    case "tools/list":
      response = { result: { tools: [] } };
      break;
    case "ping":
      response = { result: {} };
      break;
    default:
      response = { error: { code: -32601, message: "Method not found" } };
  }
  console.log(JSON.stringify({ jsonrpc: "2.0", id: request.id, ...response }));
}
