-- ============================================================================
-- Cloud backup of a user's on-device app data (journal, dreams, moods,
-- gratitude, goals, reminders, hobbies, etc.). One JSON snapshot per user.
-- Run this once in the Supabase SQL editor.
-- ============================================================================

create table if not exists public.user_backups (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_backups enable row level security;

-- A user can read only their own backup.
drop policy if exists "read own backup" on public.user_backups;
create policy "read own backup" on public.user_backups
  for select to authenticated using (auth.uid() = user_id);

-- A user can create their own backup row.
drop policy if exists "insert own backup" on public.user_backups;
create policy "insert own backup" on public.user_backups
  for insert to authenticated with check (auth.uid() = user_id);

-- A user can overwrite their own backup.
drop policy if exists "update own backup" on public.user_backups;
create policy "update own backup" on public.user_backups
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
