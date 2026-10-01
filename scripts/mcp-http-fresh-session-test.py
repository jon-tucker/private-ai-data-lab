#!/usr/bin/env python3
"""Verify database tools work without a preceding client-side connect call."""
import json
import os
import ssl
import sys
import urllib.request

base_url = sys.argv[1]
ca_file = sys.argv[2]
source_schema = os.environ['MCP_SOURCE_SCHEMA']
database_user = os.environ['MCP_DATABASE_USER']
context = ssl.create_default_context(cafile=ca_file)


def post(message, session=None):
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream',
    }
    if session:
        headers['Mcp-Session-Id'] = session
    request = urllib.request.Request(
        base_url, data=json.dumps(message).encode(), headers=headers, method='POST'
    )
    with urllib.request.urlopen(request, context=context, timeout=150) as response:
        body = response.read().decode()
        session = response.headers.get('Mcp-Session-Id', session)
    events = [line[6:] for line in body.splitlines() if line.startswith('data: ')]
    payload = json.loads(events[-1] if events else body) if body else {}
    return payload, session


_, session = post({
    'jsonrpc': '2.0', 'id': 1, 'method': 'initialize',
    'params': {
        'protocolVersion': '2024-11-05', 'capabilities': {},
        'clientInfo': {'name': 'fresh-session-verification', 'version': '1.0'},
    },
})
if not session:
    raise RuntimeError('MCP server did not assign a session')
post({'jsonrpc': '2.0', 'method': 'notifications/initialized', 'params': {}}, session)
result, _ = post({
    'jsonrpc': '2.0', 'id': 2, 'method': 'tools/call',
    'params': {
        'name': 'schema_information',
        'arguments': {
            'schema': source_schema, 'level': 'BRIEF',
            'execution_type': 'SYNCHRONOUS', 'model': 'UNKNOWN-LLM',
        },
    },
}, session)
if result.get('error') or result.get('result', {}).get('isError'):
    raise RuntimeError(f'Fresh-session schema_information failed: {result}')
print('PASS: schema_information succeeded in a fresh MCP session without a client-side connect')

_, session = post({
    'jsonrpc': '2.0', 'id': 3, 'method': 'initialize',
    'params': {
        'protocolVersion': '2024-11-05', 'capabilities': {},
        'clientInfo': {'name': 'fresh-session-verification', 'version': '1.0'},
    },
})
post({'jsonrpc': '2.0', 'method': 'notifications/initialized', 'params': {}}, session)
result, _ = post({
    'jsonrpc': '2.0', 'id': 4, 'method': 'tools/call',
    'params': {
        'name': 'sql_run',
        'arguments': {
            'sql': "select sys_context('USERENV','SESSION_USER') as session_user from dual",
            'execution_type': 'SYNCHRONOUS', 'model': 'UNKNOWN-LLM',
        },
    },
}, session)
if result.get('error') or result.get('result', {}).get('isError'):
    raise RuntimeError(f'Fresh-session sql_run failed: {result}')
texts = [item.get('text', '') for item in result['result'].get('content', [])]
if database_user not in '\n'.join(texts):
    raise RuntimeError('Read-only database identity was not verified')
print(f'PASS: sql_run succeeded as {database_user} in a separate fresh MCP session')
