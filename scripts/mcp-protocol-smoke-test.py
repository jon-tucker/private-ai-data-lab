#!/usr/bin/env python3
"""Exercise SQLcl MCP initialization and a read-only database tool sequence."""

import json
import os
import select
import subprocess
import time

server = os.environ["MCP_TEST_SERVER"]
connection = os.environ["MCP_CONNECTION_NAME"]
database_user = os.environ["MCP_DATABASE_USER"]
pdb = os.environ["ORACLE_PDB"]
source_schema = os.environ["MCP_SOURCE_SCHEMA"]
model = os.environ["MCP_TEST_MODEL"]

process = subprocess.Popen(
    [server],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
    bufsize=1,
)


def send(message):
    process.stdin.write(json.dumps(message, separators=(",", ":")) + "\n")
    process.stdin.flush()


def receive(response_id, timeout=120):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready, _, _ = select.select(
            [process.stdout], [], [], max(0, deadline - time.monotonic())
        )
        if not ready:
            break
        line = process.stdout.readline()
        if not line:
            break
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue
        if message.get("id") == response_id:
            return message
    raise TimeoutError(f"Timed out waiting for MCP response {response_id}")


def call_tool(response_id, name, arguments):
    send(
        {
            "jsonrpc": "2.0",
            "id": response_id,
            "method": "tools/call",
            "params": {"name": name, "arguments": arguments},
        }
    )
    response = receive(response_id)
    result = response.get("result", {})
    if result.get("isError"):
        raise RuntimeError(f"{name} failed: {json.dumps(result)}")
    return result


def content_text(result):
    return "\n".join(
        item.get("text", "")
        for item in result.get("content", [])
        if item.get("type") == "text"
    )


try:
    send(
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {
                    "name": "oracle-ai-platform-smoke-test",
                    "version": "0.7.0",
                },
            },
        }
    )
    initialized = receive(1)
    result = initialized.get("result", {})
    if result.get("protocolVersion") != "2024-11-05":
        raise RuntimeError(f"Unexpected MCP initialization: {json.dumps(initialized)}")

    send(
        {
            "jsonrpc": "2.0",
            "method": "notifications/initialized",
            "params": {},
        }
    )

    listed = call_tool(
        2,
        "connections_list",
        {
            "definition_type": "NON_OCI",
            "show_details": True,
            "model": model,
        },
    )
    if connection not in content_text(listed):
        raise RuntimeError(f"Saved connection not listed: {connection}")

    connected = call_tool(
        3, "connect", {"connection_name": connection, "model": model}
    )
    if connection not in content_text(connected):
        raise RuntimeError(f"Did not connect to {connection}")

    call_tool(
        4,
        "schema_information",
        {
            "schema": source_schema,
            "level": "BRIEF",
            "execution_type": "SYNCHRONOUS",
            "model": model,
        },
    )

    query = call_tool(
        5,
        "sql_run",
        {
            "sql": (
                "select sys_context('USERENV','SESSION_USER') as session_user, "
                "sys_context('USERENV','CON_NAME') as container_name "
                "from dual"
            ),
            "execution_type": "SYNCHRONOUS",
            "model": model,
        },
    )
    query_text = content_text(query)
    if database_user not in query_text or pdb not in query_text:
        raise RuntimeError(f"Unexpected SQL result: {query_text}")

    call_tool(6, "disconnect", {"model": model})

    server_info = result.get("serverInfo", {})
    print(
        "SQLcl MCP protocol smoke test passed: "
        f"server={server_info.get('name')} "
        f"version={server_info.get('version')} "
        f"protocol={result.get('protocolVersion')} "
        f"connection={connection} user={database_user} pdb={pdb}"
    )
finally:
    if process.stdin and not process.stdin.closed:
        process.stdin.close()
    process.terminate()
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=10)
    diagnostics = process.stderr.read()
    if process.returncode not in (0, -15, 143) and diagnostics:
        print(diagnostics)
