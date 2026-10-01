#!/usr/bin/env node
// Preserve SQLcl's saved read-only connection across clients that use one MCP
// session per tool call. Each supergateway session runs this bridge and its own
// SQLcl process; the bridge connects before forwarding database tools.
const { spawn } = require('node:child_process');
const readline = require('node:readline');

const connectionName = process.env.MCP_AUTO_CONNECT_NAME;
if (!/^[A-Za-z][A-Za-z0-9_-]{0,63}$/.test(connectionName || '')) {
  process.stderr.write('MCP_AUTO_CONNECT_NAME is missing or invalid\n');
  process.exit(2);
}

const child = spawn('/opt/oracle/sqlcl/bin/sql', ['-mcp'], {
  stdio: ['pipe', 'pipe', 'inherit'],
  env: process.env,
});
const replies = new Map();
let internalId = 9000000;
let queue = Promise.resolve();

readline.createInterface({ input: child.stdout }).on('line', (line) => {
  let response;
  try { response = JSON.parse(line); } catch { process.stdout.write(line + '\n'); return; }
  const key = JSON.stringify(response.id);
  const pending = replies.get(key);
  if (pending) {
    replies.delete(key);
    pending(response);
  } else {
    process.stdout.write(line + '\n');
  }
});

function callChild(message) {
  return new Promise((resolve, reject) => {
    const key = JSON.stringify(message.id);
    const timer = setTimeout(() => {
      replies.delete(key);
      reject(new Error('SQLcl MCP connect timed out'));
    }, 120000);
    replies.set(key, (response) => {
      clearTimeout(timer);
      resolve(response);
    });
    child.stdin.write(JSON.stringify(message) + '\n');
  });
}

async function forward(line) {
  let request;
  try { request = JSON.parse(line); } catch { child.stdin.write(line + '\n'); return; }
  if (request.method === 'tools/call' &&
      !/^(connect|disconnect|connections_)/.test(request.params?.name || '')) {
    try {
      const response = await callChild({
        jsonrpc: '2.0', id: ++internalId, method: 'tools/call',
        params: { name: 'connect', arguments: {
          connection_name: connectionName,
          model: request.params.arguments?.model || 'UNKNOWN-LLM',
        } },
      });
      if (response.error || response.result?.isError) {
        throw new Error('saved read-only database connection failed');
      }
    } catch (error) {
      process.stdout.write(JSON.stringify({
        jsonrpc: '2.0', id: request.id, result: {
          content: [{ type: 'text', text: error.message }], isError: true,
        },
      }) + '\n');
      return;
    }
  }
  child.stdin.write(line + '\n');
}

readline.createInterface({ input: process.stdin }).on('line', (line) => {
  queue = queue.then(() => forward(line)).catch((error) => {
    process.stderr.write(`SQLcl MCP bridge error: ${error.message}\n`);
  });
});
child.on('exit', (code) => process.exit(code || 0));
process.on('SIGTERM', () => child.kill('SIGTERM'));
