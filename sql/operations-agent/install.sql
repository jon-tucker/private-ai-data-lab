whenever sqlerror exit failure rollback
set define on
set verify off

alter session set container = &&oracle_pdb;

declare
  l_count number;
begin
  select count(*)
    into l_count
    from dba_objects
   where owner = upper('&&app_schema')
     and object_name in (
       'OPERATIONS_RUN',
       'OPERATIONS_CHECK',
       'BACKUP_CATALOG',
       'OPERATIONS_LATEST',
       'OPERATIONS_SUMMARY'
     );

  if l_count > 0 then
    raise_application_error(
      -20001,
      'Operations-agent target objects already exist; installation refused'
    );
  end if;
end;
/

create table &&app_schema..operations_run (
  run_id          number generated always as identity,
  run_name        varchar2(30) not null,
  started_utc     timestamp with time zone not null,
  completed_utc   timestamp with time zone not null,
  result_status   varchar2(10) not null,
  exit_code       number(5) not null,
  failure_count   number(5) default 0 not null,
  warning_count   number(5) default 0 not null,
  host_name       varchar2(255) not null,
  output_excerpt  varchar2(4000),
  constraint operations_run_pk primary key (run_id),
  constraint operations_run_name_ck
    check (run_name in ('backup', 'health')),
  constraint operations_run_status_ck
    check (result_status in ('FAIL', 'PASS', 'WARN')),
  constraint operations_run_counts_ck
    check (failure_count >= 0 and warning_count >= 0)
);

create index &&app_schema..operations_run_time_ix
  on &&app_schema..operations_run (completed_utc);

create table &&app_schema..operations_check (
  check_id       number generated always as identity,
  run_id         number not null,
  check_sequence number(5) not null,
  check_status   varchar2(10) not null,
  check_message  varchar2(1000) not null,
  constraint operations_check_pk primary key (check_id),
  constraint operations_check_run_fk
    foreign key (run_id)
    references &&app_schema..operations_run (run_id)
    on delete cascade,
  constraint operations_check_status_ck
    check (check_status in ('FAIL', 'PASS', 'WARN')),
  constraint operations_check_run_sequence_uk
    unique (run_id, check_sequence)
);

create index &&app_schema..operations_check_status_ix
  on &&app_schema..operations_check (check_status, run_id);

create table &&app_schema..backup_catalog (
  run_id              number not null,
  recovery_set_path   varchar2(1000) not null,
  created_utc         timestamp with time zone,
  git_commit          varchar2(64),
  git_worktree_dirty  char(1),
  verified_status     varchar2(20) default 'NOT_VERIFIED' not null,
  constraint backup_catalog_pk primary key (run_id),
  constraint backup_catalog_run_fk
    foreign key (run_id)
    references &&app_schema..operations_run (run_id)
    on delete cascade,
  constraint backup_catalog_dirty_ck
    check (git_worktree_dirty in ('N', 'Y')),
  constraint backup_catalog_verified_ck
    check (verified_status in ('FAILED', 'NOT_VERIFIED', 'VERIFIED'))
);

create view &&app_schema..operations_latest as
select
  run_id,
  run_name,
  started_utc,
  completed_utc,
  result_status,
  exit_code,
  failure_count,
  warning_count,
  host_name
from (
  select r.*,
         row_number() over (
           partition by run_name
           order by completed_utc desc, run_id desc
         ) as rn
  from &&app_schema..operations_run r
)
where rn = 1;

create view &&app_schema..operations_summary as
select
  trunc(cast(completed_utc at time zone 'UTC' as date)) as run_day_utc,
  run_name,
  count(*) as run_count,
  sum(case when result_status = 'PASS' then 1 else 0 end) as passed_count,
  sum(case when result_status = 'WARN' then 1 else 0 end) as warning_run_count,
  sum(case when result_status = 'FAIL' then 1 else 0 end) as failed_count,
  sum(failure_count) as check_failure_count,
  sum(warning_count) as check_warning_count
from &&app_schema..operations_run
group by
  trunc(cast(completed_utc at time zone 'UTC' as date)),
  run_name;

comment on table &&app_schema..operations_run is
  'Timestamped health and backup executions recorded by host observability';
comment on table &&app_schema..operations_check is
  'Individual PASS, WARN, and FAIL results emitted by operational checks';
comment on table &&app_schema..backup_catalog is
  'Recovery-set metadata associated with coordinated backup executions';
comment on table &&app_schema..operations_latest is
  'Most recent recorded execution for each operational run type';
comment on table &&app_schema..operations_summary is
  'Daily health and backup execution totals for operational analysis';

commit;

prompt Operations-agent repository installed successfully.
exit
