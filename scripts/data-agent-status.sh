#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

for variable_name in ORACLE_PDB MCP_SOURCE_SCHEMA MCP_DATABASE_ROLE; do
  variable_value="${!variable_name}"
  [[ "${variable_value}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
    die "${variable_name} must be an uppercase simple Oracle identifier"
done

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
alter session set container = ${ORACLE_PDB};
set linesize 240
set pagesize 100

select owner, object_type, status, count(*) as object_count
from dba_objects
where owner = '${MCP_SOURCE_SCHEMA}'
  and object_name in (
    'CUSTOMERS',
    'PRODUCTS',
    'ORDERS',
    'ORDER_ITEMS',
    'ORDER_SUMMARY',
    'SALES_DETAIL'
  )
group by owner, object_type, status
order by object_type, status;

select
  (select count(*) from ${MCP_SOURCE_SCHEMA}.customers) as customers,
  (select count(*) from ${MCP_SOURCE_SCHEMA}.products) as products,
  (select count(*) from ${MCP_SOURCE_SCHEMA}.orders) as orders,
  (select count(*) from ${MCP_SOURCE_SCHEMA}.order_items) as order_items,
  (select sum(order_total)
     from ${MCP_SOURCE_SCHEMA}.order_summary
    where order_status in ('COMPLETED', 'SHIPPED')) as recognized_revenue
from dual;

select table_name, privilege
from dba_tab_privs
where owner = '${MCP_SOURCE_SCHEMA}'
  and grantee = '${MCP_DATABASE_ROLE}'
order by table_name, privilege;

exit
SQL
