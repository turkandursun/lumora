-- ASTRA Focus Sessions
-- Run manually in the Supabase SQL editor. This file is intentionally not
-- applied automatically by the Flutter application.

create table if not exists public.focus_sessions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  task_label text null,
  planned_duration_seconds integer not null,
  actual_duration_seconds integer not null,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint focus_sessions_planned_duration_positive
    check (planned_duration_seconds > 0),
  constraint focus_sessions_actual_duration_nonnegative
    check (actual_duration_seconds >= 0),
  constraint focus_sessions_task_label_length
    check (task_label is null or char_length(task_label) <= 120),
  constraint focus_sessions_time_order
    check (ended_at >= started_at)
);

create index if not exists focus_sessions_user_started_at_idx
  on public.focus_sessions (user_id, started_at desc);

create or replace function public.set_focus_sessions_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists focus_sessions_set_updated_at
  on public.focus_sessions;
create trigger focus_sessions_set_updated_at
before update on public.focus_sessions
for each row execute function public.set_focus_sessions_updated_at();

alter table public.focus_sessions enable row level security;

drop policy if exists "focus_sessions_select_own"
  on public.focus_sessions;
create policy "focus_sessions_select_own"
  on public.focus_sessions
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "focus_sessions_insert_own"
  on public.focus_sessions;
create policy "focus_sessions_insert_own"
  on public.focus_sessions
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "focus_sessions_update_own"
  on public.focus_sessions;
create policy "focus_sessions_update_own"
  on public.focus_sessions
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "focus_sessions_delete_own"
  on public.focus_sessions;
create policy "focus_sessions_delete_own"
  on public.focus_sessions
  for delete
  to authenticated
  using (auth.uid() = user_id);

revoke all on table public.focus_sessions from anon;
grant select, insert, update, delete on table public.focus_sessions
  to authenticated;
