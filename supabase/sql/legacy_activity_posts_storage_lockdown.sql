-- Release Day 1: lock down the unused activity-posts Storage bucket.
-- Existing objects are intentionally preserved. The bucket is private and
-- every client policy created by the historical Activity Posts SQL scripts is
-- removed. Service-role Storage administration continues to bypass RLS.

update storage.buckets
set public = false
where id = 'activity-posts';

drop policy if exists "upload post photos" on storage.objects;
drop policy if exists "read post photos" on storage.objects;
drop policy if exists "upload own post photos" on storage.objects;
drop policy if exists "read own post photos" on storage.objects;
drop policy if exists "update own post photos" on storage.objects;
drop policy if exists "delete own post photos" on storage.objects;

