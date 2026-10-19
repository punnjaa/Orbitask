create table subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  name text not null,
  color text not null default '#7C6CF0',
  created_at timestamptz default now()
);
create table tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  subject_id uuid not null references subjects on delete cascade,
  title text not null,
  description text,
  deadline date not null,
  workload_score int not null default 50,
  notified_d3 boolean default false,
  notified_d1 boolean default false,
  created_at timestamptz default now()
);
create table subtasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  task_id uuid not null references tasks on delete cascade,
  title text not null,
  plan_date date not null,
  minutes int not null default 30,
  done boolean not null default false
);
create table line_links (
  user_id uuid primary key references auth.users on delete cascade,
  line_user_id text unique,
  link_code text,
  code_expires_at timestamptz,
  linked_at timestamptz
);
alter table subjects enable row level security;
alter table tasks enable row level security;
alter table subtasks enable row level security;
alter table line_links enable row level security;
create policy own_subjects on subjects for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_tasks on tasks for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_subtasks on subtasks for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_line on line_links for select using (user_id = auth.uid());
