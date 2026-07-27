whenever sqlerror exit failure rollback
set define on
set verify off

alter session set container = &&oracle_pdb;

begin
  for object_name in (
    select 'OPERATIONS_SUMMARY' name from dual union all
    select 'OPERATIONS_LATEST' from dual
  ) loop
    begin
      execute immediate
        'drop view &&app_schema..' || object_name.name;
    exception
      when others then
        if sqlcode != -942 then raise; end if;
    end;
  end loop;

  for object_name in (
    select 'BACKUP_CATALOG' name from dual union all
    select 'OPERATIONS_CHECK' from dual union all
    select 'OPERATIONS_RUN' from dual
  ) loop
    begin
      execute immediate
        'drop table &&app_schema..' || object_name.name ||
        ' cascade constraints purge';
    exception
      when others then
        if sqlcode != -942 then raise; end if;
    end;
  end loop;
end;
/

exit
