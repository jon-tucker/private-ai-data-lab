whenever sqlerror exit failure rollback
set define on
set verify off

alter session set container = &&oracle_pdb;

begin
  for item in (
    select object_name, object_type
    from dba_objects
    where owner = upper('&&app_schema')
      and object_name in (
        'CUSTOMERS',
        'PRODUCTS',
        'ORDERS',
        'ORDER_ITEMS',
        'ORDER_SUMMARY',
        'SALES_DETAIL'
      )
    order by
      case object_type when 'VIEW' then 1 when 'TABLE' then 2 else 3 end,
      case object_name
        when 'ORDER_ITEMS' then 1
        when 'ORDERS' then 2
        when 'PRODUCTS' then 3
        when 'CUSTOMERS' then 4
        else 0
      end
  ) loop
    execute immediate
      'drop ' || item.object_type || ' ' ||
      dbms_assert.enquote_name(upper('&&app_schema'), false) || '.' ||
      dbms_assert.enquote_name(item.object_name, false) ||
      case when item.object_type = 'TABLE' then ' cascade constraints purge' end;
  end loop;
end;
/

prompt Data-agent demonstration schema removed.
exit
