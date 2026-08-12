-- Storage bucket for cached ElevenLabs meditation voice clips.
--
-- Paste into Supabase SQL Editor and run once. Creates a PUBLIC bucket so the
-- app can stream the generated mp3 files by URL. The Edge Function writes to it
-- with the service role (which bypasses RLS), so no extra write policy is
-- needed; public read comes from the bucket's `public = true` flag.

insert into storage.buckets (id, name, public)
values ('meditation-voice', 'meditation-voice', true)
on conflict (id) do update set public = true;
