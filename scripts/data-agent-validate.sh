#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'
for variable_name in ORACLE_PDB MCP_DATABASE_USER MCP_DATABASE_ROLE; do
  variable_value="${!variable_name}"
  [[ "${variable_value}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
    die "${variable_name} must be an uppercase simple Oracle identifier"
done

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};
set serveroutput on
set linesize 240
set pagesize 100

declare
  l_value number;

  procedure assert_equal(
    p_label    varchar2,
    p_actual   number,
    p_expected number
  ) is
  begin
    if p_actual != p_expected then
      raise_application_error(
        -20001,
        p_label || ': expected ' || p_expected || ', found ' || p_actual
      );
    end if;
  end;

begin
  select count(*) into l_value from ${MCP_SOURCE_SCHEMA}.customers;
  assert_equal('customer count', l_value, 8);

  select count(*) into l_value from ${MCP_SOURCE_SCHEMA}.products;
  assert_equal('product count', l_value, 8);

  select count(*) into l_value from ${MCP_SOURCE_SCHEMA}.orders;
  assert_equal('order count', l_value, 12);

  select count(*) into l_value from ${MCP_SOURCE_SCHEMA}.order_items;
  assert_equal('order-item count', l_value, 22);

  select count(*) into l_value from ${MCP_SOURCE_SCHEMA}.order_summary;
  assert_equal('order-summary count', l_value, 12);

  select sum(order_total)
    into l_value
    from ${MCP_SOURCE_SCHEMA}.order_summary
   where order_status in ('COMPLETED', 'SHIPPED');
  assert_equal('recognized revenue', l_value, 12027);

  select count(*)
    into l_value
    from dba_tab_privs
   where owner = '${MCP_SOURCE_SCHEMA}'
     and grantee = '${MCP_DATABASE_ROLE}'
     and privilege = 'SELECT'
     and table_name in (
       'CUSTOMERS',
       'PRODUCTS',
       'ORDERS',
       'ORDER_ITEMS',
       'ORDER_SUMMARY',
       'SALES_DETAIL'
     );
  assert_equal('MCP SELECT grant count', l_value, 6);

  select count(*)
    into l_value
    from dba_sys_privs
   where grantee = '${MCP_DATABASE_USER}'
     and privilege != 'CREATE SESSION';
  assert_equal('unexpected MCP system privileges', l_value, 0);

  select count(*)
    into l_value
    from dba_ts_quotas
   where username = '${MCP_DATABASE_USER}'
     and max_bytes != 0;
  assert_equal('writable MCP quotas', l_value, 0);

  select count(*)
    into l_value
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
     and status != 'VALID';
  assert_equal('invalid data-agent objects', l_value, 0);

  dbms_output.put_line('Deterministic row counts, revenue, grants, and MCP boundaries passed.');
end;
/

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

exit
SQL

printf 'Data-agent database validation passed.\n'
