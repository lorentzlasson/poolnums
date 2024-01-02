create table selection (
  time timestamptz not null default current_timestamp,
  a int not null,
  b int not null,
  c int not null
)
