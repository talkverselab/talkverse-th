-- 앱 검수용 개발자 메모 (2026-09-23) — 모든 언어 앱 공용.
-- 앱의 어느 화면에서든 메모 + 화면 캡처 + 맥락(스크립트 id 등)을 남기고, 처리 결과(resolution)를 앱에서 본다.
create table if not exists public.tv_dev_notes (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  app_lang text not null,
  app_build int,
  platform text,
  screen text,
  context jsonb not null default '{}'::jsonb,
  note text not null check (char_length(note) between 1 and 4000),
  shot_path text,
  status text not null default 'open' check (status in ('open','doing','done','wontfix')),
  resolution text,
  resolved_at timestamptz
);
create index if not exists tv_dev_notes_open_idx on public.tv_dev_notes (status, created_at desc);
create index if not exists tv_dev_notes_user_idx on public.tv_dev_notes (user_id);
alter table public.tv_dev_notes enable row level security;

drop policy if exists "dev notes: insert own" on public.tv_dev_notes;
create policy "dev notes: insert own" on public.tv_dev_notes
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "dev notes: read own" on public.tv_dev_notes;
create policy "dev notes: read own" on public.tv_dev_notes
  for select to authenticated using (user_id = (select auth.uid()));

-- 화면 캡처: 비공개 버킷, 본인 폴더(<uid>/…)에만 올리고 읽는다.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('dev-notes', 'dev-notes', false, 5242880, array['image/png','image/jpeg'])
on conflict (id) do nothing;

drop policy if exists "dev-notes: upload own folder" on storage.objects;
create policy "dev-notes: upload own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'dev-notes' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists "dev-notes: read own folder" on storage.objects;
create policy "dev-notes: read own folder" on storage.objects
  for select to authenticated
  using (bucket_id = 'dev-notes' and (storage.foldername(name))[1] = (select auth.uid())::text);
