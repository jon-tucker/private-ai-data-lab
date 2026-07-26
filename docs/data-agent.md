# Read-only sales data agent

Version 0.10 introduces a deterministic sales dataset owned by `ORACLE_AI`.
It is intentionally small enough to audit while supporting useful questions
about customers, products, orders, revenue, regions, and sales channels.

## Data model

The installer creates four tables and two reporting views:

- `CUSTOMERS`
- `PRODUCTS`
- `ORDERS`
- `ORDER_ITEMS`
- `ORDER_SUMMARY`
- `SALES_DETAIL`

The fixed dataset contains 8 customers, 8 products, 12 orders, and 22 order
items. Recognized revenue from `COMPLETED` and `SHIPPED` orders is `12027`.
These invariants make regression tests repeatable.

## Install and validate

Run from the repository root:

```bash
./scripts/data-agent-install.sh
./scripts/data-agent-status.sh
./scripts/data-agent-smoke-test.sh
```

Installation refuses to overwrite any existing target object. After creating
the objects, it synchronizes `SELECT` grants to
`ORACLE_AI_MCP_READ_ROLE`. The MCP identity remains `ORACLE_AI_MCP`; it does
not receive the `ORACLE_AI` workspace credential.

## Agent Factory flow

Use the existing `oracle_sqlcl_readonly` MCP server and allow only the
reviewed read-oriented tools:

- `connect`
- `connections_list`
- `disconnect`
- `schema_information`
- `sql_run`
- `tables`

The agent instructions should require connection
`oracle_ai_readonly`, permit only `SELECT` and metadata inspection, and
prohibit DDL, DML, PL/SQL, administrative commands, and SQLcl commands.

Suggested verification questions:

1. What is recognized revenue by sales channel?
2. Which three products generated the most recognized revenue?
3. Show recognized revenue and order count by customer region.
4. Identify the connected session user and pluggable database.

Database privileges remain the enforcement boundary even if a model ignores
its instructions. The smoke test confirms read access and verifies that an
object-creation attempt is rejected.

## Removal

Removal is deliberately explicit:

```bash
./scripts/data-agent-uninstall.sh --confirm
```

This removes only the six objects listed above. It does not remove the
`ORACLE_AI` schema, APEX workspace, MCP identity, saved connection, or Agent
Factory flow.
