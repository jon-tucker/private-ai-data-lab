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
       'CUSTOMERS',
       'PRODUCTS',
       'ORDERS',
       'ORDER_ITEMS',
       'ORDER_SUMMARY',
       'SALES_DETAIL'
     );

  if l_count > 0 then
    raise_application_error(
      -20001,
      'Data-agent target objects already exist; installation refused'
    );
  end if;
end;
/

create table &&app_schema..customers (
  customer_id   number(10) constraint customers_pk primary key,
  customer_name varchar2(100) not null,
  region        varchar2(20) not null,
  signup_date   date not null,
  status        varchar2(10) not null,
  constraint customers_region_ck
    check (region in ('MIDWEST', 'NORTHEAST', 'SOUTH', 'WEST')),
  constraint customers_status_ck
    check (status in ('ACTIVE', 'INACTIVE'))
);

create table &&app_schema..products (
  product_id   number(10) constraint products_pk primary key,
  product_name varchar2(100) not null,
  category     varchar2(20) not null,
  unit_price   number(10,2) not null,
  active       char(1) default 'Y' not null,
  constraint products_category_ck
    check (category in ('HARDWARE', 'SERVICES', 'SOFTWARE')),
  constraint products_price_ck check (unit_price > 0),
  constraint products_active_ck check (active in ('Y', 'N'))
);

create table &&app_schema..orders (
  order_id     number(10) constraint orders_pk primary key,
  customer_id  number(10) not null,
  order_date   date not null,
  order_status varchar2(12) not null,
  sales_channel varchar2(10) not null,
  constraint orders_customer_fk
    foreign key (customer_id)
    references &&app_schema..customers (customer_id),
  constraint orders_status_ck
    check (order_status in ('CANCELLED', 'COMPLETED', 'PENDING', 'SHIPPED')),
  constraint orders_channel_ck
    check (sales_channel in ('DIRECT', 'PARTNER', 'WEB'))
);

create table &&app_schema..order_items (
  order_item_id number(10) constraint order_items_pk primary key,
  order_id      number(10) not null,
  product_id    number(10) not null,
  quantity      number(8) not null,
  unit_price    number(10,2) not null,
  constraint order_items_order_fk
    foreign key (order_id)
    references &&app_schema..orders (order_id),
  constraint order_items_product_fk
    foreign key (product_id)
    references &&app_schema..products (product_id),
  constraint order_items_quantity_ck check (quantity > 0),
  constraint order_items_price_ck check (unit_price > 0),
  constraint order_items_order_product_uk unique (order_id, product_id)
);

create index &&app_schema..orders_customer_ix
  on &&app_schema..orders (customer_id, order_date);

create index &&app_schema..order_items_product_ix
  on &&app_schema..order_items (product_id);

insert all
  into &&app_schema..customers values (1, 'Acme Manufacturing', 'MIDWEST', date '2025-01-10', 'ACTIVE')
  into &&app_schema..customers values (2, 'Blue River Health', 'SOUTH', date '2025-02-14', 'ACTIVE')
  into &&app_schema..customers values (3, 'Cedar Analytics', 'WEST', date '2025-03-03', 'ACTIVE')
  into &&app_schema..customers values (4, 'Delta Retail Group', 'NORTHEAST', date '2025-04-22', 'ACTIVE')
  into &&app_schema..customers values (5, 'Evergreen Logistics', 'WEST', date '2025-06-09', 'ACTIVE')
  into &&app_schema..customers values (6, 'Frontier Education', 'MIDWEST', date '2025-08-18', 'ACTIVE')
  into &&app_schema..customers values (7, 'Granite Financial', 'NORTHEAST', date '2025-10-01', 'ACTIVE')
  into &&app_schema..customers values (8, 'Harbor Hospitality', 'SOUTH', date '2025-11-12', 'INACTIVE')
select 1 from dual;

insert all
  into &&app_schema..products values (101, 'Laptop Dock', 'HARDWARE', 189.00, 'Y')
  into &&app_schema..products values (102, 'Mechanical Keyboard', 'HARDWARE', 129.00, 'Y')
  into &&app_schema..products values (103, '4K Monitor', 'HARDWARE', 499.00, 'Y')
  into &&app_schema..products values (104, 'USB-C Hub', 'HARDWARE', 79.00, 'Y')
  into &&app_schema..products values (105, 'Analytics Pro License', 'SOFTWARE', 1200.00, 'Y')
  into &&app_schema..products values (106, 'Support Plan', 'SERVICES', 300.00, 'Y')
  into &&app_schema..products values (107, 'Webcam', 'HARDWARE', 149.00, 'Y')
  into &&app_schema..products values (108, 'Headset', 'HARDWARE', 99.00, 'Y')
select 1 from dual;

insert all
  into &&app_schema..orders values (1001, 1, date '2026-01-15', 'COMPLETED', 'DIRECT')
  into &&app_schema..orders values (1002, 2, date '2026-01-20', 'COMPLETED', 'WEB')
  into &&app_schema..orders values (1003, 3, date '2026-02-05', 'COMPLETED', 'PARTNER')
  into &&app_schema..orders values (1004, 4, date '2026-02-18', 'CANCELLED', 'WEB')
  into &&app_schema..orders values (1005, 5, date '2026-03-02', 'COMPLETED', 'DIRECT')
  into &&app_schema..orders values (1006, 6, date '2026-03-22', 'COMPLETED', 'WEB')
  into &&app_schema..orders values (1007, 7, date '2026-04-11', 'PENDING', 'PARTNER')
  into &&app_schema..orders values (1008, 1, date '2026-04-30', 'COMPLETED', 'WEB')
  into &&app_schema..orders values (1009, 2, date '2026-05-14', 'COMPLETED', 'DIRECT')
  into &&app_schema..orders values (1010, 3, date '2026-06-03', 'COMPLETED', 'PARTNER')
  into &&app_schema..orders values (1011, 5, date '2026-06-19', 'SHIPPED', 'WEB')
  into &&app_schema..orders values (1012, 6, date '2026-07-07', 'COMPLETED', 'DIRECT')
select 1 from dual;

insert all
  into &&app_schema..order_items values (1, 1001, 101, 2, 189.00)
  into &&app_schema..order_items values (2, 1001, 102, 2, 129.00)
  into &&app_schema..order_items values (3, 1002, 103, 1, 499.00)
  into &&app_schema..order_items values (4, 1002, 104, 3, 79.00)
  into &&app_schema..order_items values (5, 1003, 105, 1, 1200.00)
  into &&app_schema..order_items values (6, 1003, 106, 1, 300.00)
  into &&app_schema..order_items values (7, 1004, 107, 2, 149.00)
  into &&app_schema..order_items values (8, 1005, 103, 2, 499.00)
  into &&app_schema..order_items values (9, 1005, 101, 2, 189.00)
  into &&app_schema..order_items values (10, 1006, 108, 5, 99.00)
  into &&app_schema..order_items values (11, 1006, 102, 1, 129.00)
  into &&app_schema..order_items values (12, 1007, 105, 1, 1200.00)
  into &&app_schema..order_items values (13, 1008, 104, 10, 79.00)
  into &&app_schema..order_items values (14, 1008, 107, 3, 149.00)
  into &&app_schema..order_items values (15, 1009, 106, 4, 300.00)
  into &&app_schema..order_items values (16, 1010, 101, 1, 189.00)
  into &&app_schema..order_items values (17, 1010, 103, 1, 499.00)
  into &&app_schema..order_items values (18, 1010, 108, 2, 99.00)
  into &&app_schema..order_items values (19, 1011, 102, 4, 129.00)
  into &&app_schema..order_items values (20, 1011, 104, 4, 79.00)
  into &&app_schema..order_items values (21, 1012, 105, 2, 1200.00)
  into &&app_schema..order_items values (22, 1012, 106, 2, 300.00)
select 1 from dual;

create view &&app_schema..order_summary as
select
  o.order_id,
  o.order_date,
  o.order_status,
  o.sales_channel,
  c.customer_id,
  c.customer_name,
  c.region,
  sum(oi.quantity * oi.unit_price) as order_total
from &&app_schema..orders o
join &&app_schema..customers c
  on c.customer_id = o.customer_id
join &&app_schema..order_items oi
  on oi.order_id = o.order_id
group by
  o.order_id,
  o.order_date,
  o.order_status,
  o.sales_channel,
  c.customer_id,
  c.customer_name,
  c.region;

create view &&app_schema..sales_detail as
select
  o.order_id,
  o.order_date,
  o.order_status,
  o.sales_channel,
  c.customer_name,
  c.region,
  p.product_name,
  p.category,
  oi.quantity,
  oi.unit_price,
  oi.quantity * oi.unit_price as line_total
from &&app_schema..orders o
join &&app_schema..customers c
  on c.customer_id = o.customer_id
join &&app_schema..order_items oi
  on oi.order_id = o.order_id
join &&app_schema..products p
  on p.product_id = oi.product_id;

comment on table &&app_schema..customers is
  'Deterministic demonstration customers for the v0.10 data agent';
comment on table &&app_schema..products is
  'Deterministic demonstration catalog for the v0.10 data agent';
comment on table &&app_schema..orders is
  'Deterministic demonstration order headers for the v0.10 data agent';
comment on table &&app_schema..order_items is
  'Deterministic demonstration order lines for the v0.10 data agent';
comment on table &&app_schema..order_summary is
  'One row per order with customer, region, status, and total';
comment on table &&app_schema..sales_detail is
  'Read-oriented sales lines enriched with customer and product attributes';

commit;

prompt Data-agent demonstration schema installed successfully.
exit
