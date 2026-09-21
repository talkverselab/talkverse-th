-- Talkverse 회원 · 요금제 · 결제 · 이용권 · 코스 동기화  (Supabase 프로젝트 Talkverse, 2026-09-21)
-- 모든 언어 앱 + talkverse.uk 가 같은 표를 쓴다. 접두사 tv_ (세무조정 taxadj_ 와 분리).
-- 원칙: 앱(anon 키)은 본인 행만 읽고 쓴다. 주문·구독·이용권은 Worker(service role)만 쓴다.

-- 1) 프로필 — auth.users 1:1. 가입하면 트리거가 만든다.
create table if not exists public.tv_profiles (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  gender       text check (gender in ('m','f')),
  market       text not null default 'kr' check (market in ('kr','global')),  -- kr: 네이버·카카오·구글 / global: 구글
  country      text,                       -- ISO 2자리
  ui_lang      text not null default 'ko', -- ko en ja zh
  marketing_ok boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- 2) 로그인 수단 — 구글·카카오·이메일은 auth.identities 에도 있지만, 네이버(Worker 경유)까지 한 표로 본다.
create table if not exists public.tv_identities (
  user_id      uuid not null references auth.users(id) on delete cascade,
  provider     text not null check (provider in ('google','kakao','naver','email','apple')),
  provider_uid text not null,
  email        text,
  linked_at    timestamptz not null default now(),
  primary key (provider, provider_uid),
  unique (user_id, provider)
);

-- 3) 상품 — 무엇에 대한 권리인가. langs 가 빈 배열이면 전체.
create table if not exists public.tv_products (
  id      text primary key,          -- 예: lang_th · set_sea · all
  kind    text not null check (kind in ('language','set','all')),
  langs   text[] not null default '{}',  -- 언어 코드 목록 (set·language)
  name_ko text not null,
  name_en text,
  sort    int  not null default 100,
  active  boolean not null default true
);

-- 4) 요금제 — 상품 × 기간 × 가격. 스토어 SKU 는 채널마다 다르므로 여기 둔다.
create table if not exists public.tv_plans (
  id          text primary key,     -- 예: lang_th_m · lang_th_y · set_sea_y · all_y
  product_id  text not null references public.tv_products(id),
  period      text not null check (period in ('month','year')),
  price_krw   int,
  price_usd   numeric(8,2),
  sku_google  text,                 -- Google Play 정기결제 ID
  sku_apple   text,                 -- App Store 상품 ID
  trial_days  int not null default 0,
  active      boolean not null default true
);

-- 5) 주문 — 결제 1건. 채널 4곳(웹 국내·웹 해외·구글플레이·앱스토어) + 관리자 수동.
create table if not exists public.tv_orders (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  plan_id      text not null references public.tv_plans(id),
  channel      text not null check (channel in ('web_kr','web_global','google_play','app_store','admin')),
  provider_ref text,                -- PG 결제번호 · 구매 토큰 · 영수증 ID
  amount       numeric(12,2) not null,
  currency     text not null default 'KRW',
  status       text not null default 'pending' check (status in ('pending','paid','refunded','canceled','failed')),
  raw          jsonb,               -- 채널이 준 원본(웹훅 본문)
  created_at   timestamptz not null default now(),
  paid_at      timestamptz
);
create index if not exists tv_orders_user on public.tv_orders(user_id, created_at desc);
create unique index if not exists tv_orders_channel_ref on public.tv_orders(channel, provider_ref) where provider_ref is not null;

-- 6) 구독 — 유효 기간이 있는 권리. 정기결제는 갱신마다 ends_at 이 늘어난다.
create table if not exists public.tv_subscriptions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  plan_id     text not null references public.tv_plans(id),
  order_id    uuid references public.tv_orders(id),
  channel     text not null check (channel in ('web_kr','web_global','google_play','app_store','admin')),
  channel_ref text,                 -- 구독 ID(스토어) · 빌링키(웹)
  status      text not null default 'active' check (status in ('active','grace','canceled','expired','refunded')),
  starts_at   timestamptz not null default now(),
  ends_at     timestamptz not null,
  auto_renew  boolean not null default true,
  updated_at  timestamptz not null default now()
);
create index if not exists tv_subs_user on public.tv_subscriptions(user_id, ends_at desc);

-- 7) 코스 동기화 — 앱마다(app_lang) 답 한 벌, 완료 회차 여러 줄.
create table if not exists public.tv_course_answers (
  user_id    uuid not null references auth.users(id) on delete cascade,
  app_lang   text not null,          -- th zh ja …
  answers    jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, app_lang)
);
create table if not exists public.tv_course_progress (
  user_id    uuid not null references auth.users(id) on delete cascade,
  app_lang   text not null,
  script_key text not null,          -- 예: biz.romance.dinner#1 (성별판 @… 은 뗀 것)
  done_at    timestamptz not null default now(),
  primary key (user_id, app_lang, script_key)
);

-- 8) 이용권 계산 — "이 사용자가 이 언어를 지금 쓸 수 있나". 앱·Worker 둘 다 이 함수만 본다.
create or replace function public.tv_entitlements(p_user uuid)
returns table (lang text, ends_at timestamptz, plan_id text, source text)
language sql stable security definer set search_path = public as $$
  with subs as (
    select s.plan_id, s.ends_at, s.channel, p.langs, p.kind
    from tv_subscriptions s
    join tv_plans pl on pl.id = s.plan_id
    join tv_products p on p.id = pl.product_id
    where s.user_id = p_user
      and s.status in ('active','grace')
      and s.ends_at > now()
  ),
  langs as (
    select distinct l.code from (
      select unnest(langs) as code from subs where kind <> 'all'
      union select unnest(array['th','zh','ja','ko','vi','id','my','en','es','de','fr','it','pt','tr','hu','hi','fa','ru','mn','ar']) where exists (select 1 from subs where kind = 'all')
    ) l
  )
  select l.code, max(s.ends_at), (array_agg(s.plan_id order by s.ends_at desc))[1], (array_agg(s.channel order by s.ends_at desc))[1]
  from langs l
  join subs s on s.kind = 'all' or l.code = any(s.langs)
  group by l.code;
$$;

create or replace function public.tv_my_entitlements()
returns table (lang text, ends_at timestamptz, plan_id text, source text)
language sql stable security definer set search_path = public as $$
  select * from public.tv_entitlements(auth.uid());
$$;

create or replace function public.tv_has_access(p_lang text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.tv_entitlements(auth.uid()) where lang = p_lang);
$$;

-- 9) 가입 트리거 — auth.users 에 행이 생기면 프로필 + 로그인 수단 기록.
create or replace function public.tv_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare prov text;
begin
  prov := coalesce(new.raw_app_meta_data->>'provider', 'email');
  insert into public.tv_profiles (user_id, display_name, market)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(coalesce(new.email,''), '@', 1)),
          case when prov in ('kakao','naver') then 'kr' else 'kr' end)
  on conflict (user_id) do nothing;
  if prov in ('google','kakao','apple','email') then
    insert into public.tv_identities (user_id, provider, provider_uid, email)
    values (new.id, prov, coalesce(new.raw_user_meta_data->>'provider_id', new.raw_user_meta_data->>'sub', new.id::text), new.email)
    on conflict do nothing;
  end if;
  return new;
end $$;
drop trigger if exists tv_on_auth_user_created on auth.users;
create trigger tv_on_auth_user_created after insert on auth.users
  for each row execute function public.tv_handle_new_user();

-- 10) updated_at 자동 갱신
create or replace function public.tv_touch() returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end $$;
drop trigger if exists tv_profiles_touch on public.tv_profiles;
create trigger tv_profiles_touch before update on public.tv_profiles for each row execute function public.tv_touch();
drop trigger if exists tv_subs_touch on public.tv_subscriptions;
create trigger tv_subs_touch before update on public.tv_subscriptions for each row execute function public.tv_touch();
drop trigger if exists tv_answers_touch on public.tv_course_answers;
create trigger tv_answers_touch before update on public.tv_course_answers for each row execute function public.tv_touch();

-- 11) RLS — 앱은 본인 행만. 상품·요금제는 누구나 읽기. 주문·구독은 본인 읽기만(쓰기는 service role).
alter table public.tv_profiles        enable row level security;
alter table public.tv_identities      enable row level security;
alter table public.tv_products        enable row level security;
alter table public.tv_plans           enable row level security;
alter table public.tv_orders          enable row level security;
alter table public.tv_subscriptions   enable row level security;
alter table public.tv_course_answers  enable row level security;
alter table public.tv_course_progress enable row level security;

drop policy if exists tv_profiles_own on public.tv_profiles;
create policy tv_profiles_own on public.tv_profiles for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists tv_identities_own on public.tv_identities;
create policy tv_identities_own on public.tv_identities for select to authenticated using (user_id = auth.uid());
drop policy if exists tv_products_read on public.tv_products;
create policy tv_products_read on public.tv_products for select to anon, authenticated using (active);
drop policy if exists tv_plans_read on public.tv_plans;
create policy tv_plans_read on public.tv_plans for select to anon, authenticated using (active);
drop policy if exists tv_orders_own on public.tv_orders;
create policy tv_orders_own on public.tv_orders for select to authenticated using (user_id = auth.uid());
drop policy if exists tv_subs_own on public.tv_subscriptions;
create policy tv_subs_own on public.tv_subscriptions for select to authenticated using (user_id = auth.uid());
drop policy if exists tv_answers_own on public.tv_course_answers;
create policy tv_answers_own on public.tv_course_answers for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists tv_progress_own on public.tv_course_progress;
create policy tv_progress_own on public.tv_course_progress for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

grant execute on function public.tv_my_entitlements() to authenticated;
grant execute on function public.tv_has_access(text) to authenticated;

-- 12) 상품·요금제 초기값 — 가격은 자리만 잡아 둔 값. 실제 금액은 나중에 UPDATE.
insert into public.tv_products (id, kind, langs, name_ko, name_en, sort) values
  ('lang_th', 'language', '{th}', '태국어', 'Thai', 10),
  ('lang_zh', 'language', '{zh}', '중국어', 'Chinese', 11),
  ('lang_ja', 'language', '{ja}', '일본어', 'Japanese', 12),
  ('lang_vi', 'language', '{vi}', '베트남어', 'Vietnamese', 13),
  ('lang_ko', 'language', '{ko}', '한국어', 'Korean', 14),
  ('set_sea', 'set', '{th,vi,id,my}', '동남아 세트', 'Southeast Asia set', 50),
  ('set_cjk', 'set', '{zh,ja,ko}', '한중일 세트', 'CJK set', 51),
  ('all',     'all', '{}', '전체 언어', 'All languages', 90)
on conflict (id) do nothing;

insert into public.tv_plans (id, product_id, period, price_krw, price_usd) values
  ('lang_th_m', 'lang_th', 'month', 4900, 3.99), ('lang_th_y', 'lang_th', 'year', 39000, 29.99),
  ('lang_zh_m', 'lang_zh', 'month', 4900, 3.99), ('lang_zh_y', 'lang_zh', 'year', 39000, 29.99),
  ('lang_ja_m', 'lang_ja', 'month', 4900, 3.99), ('lang_ja_y', 'lang_ja', 'year', 39000, 29.99),
  ('lang_vi_m', 'lang_vi', 'month', 4900, 3.99), ('lang_vi_y', 'lang_vi', 'year', 39000, 29.99),
  ('lang_ko_m', 'lang_ko', 'month', 4900, 3.99), ('lang_ko_y', 'lang_ko', 'year', 39000, 29.99),
  ('set_sea_m', 'set_sea', 'month', 9900, 7.99), ('set_sea_y', 'set_sea', 'year', 79000, 59.99),
  ('set_cjk_m', 'set_cjk', 'month', 9900, 7.99), ('set_cjk_y', 'set_cjk', 'year', 79000, 59.99),
  ('all_m', 'all', 'month', 14900, 11.99), ('all_y', 'all', 'year', 119000, 89.99)
on conflict (id) do nothing;
