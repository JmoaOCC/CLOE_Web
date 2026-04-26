-- C.L.O.E. COACH
-- Pega este archivo completo en Supabase SQL Editor y ejecútalo.

create table if not exists profiles (
  id           uuid references auth.users(id) on delete cascade primary key,
  full_name    text,
  email        text,
  role         text default 'user',
  status       text default 'pending',
  week         integer default 1,
  age          integer,
  sex          text,
  weight_kg    numeric,
  height_cm    integer,
  goal         text,
  notes        text,
  quincena1_plan text,
  current_plan text,
  latest_report text,
  latest_report_at timestamptz,
  created_at   timestamptz default now()
);

alter table profiles add column if not exists onboarding_completed boolean default false;
alter table profiles add column if not exists onboarding_data jsonb;
alter table profiles add column if not exists quincena1_plan text;
update profiles
set quincena1_plan = coalesce(quincena1_plan, current_plan)
where quincena1_plan is null and current_plan is not null;
alter table profiles add column if not exists latest_report text;
alter table profiles add column if not exists latest_report_at timestamptz;
alter table profiles add column if not exists plan_strength jsonb;
alter table profiles add column if not exists plan_running jsonb;
alter table profiles add column if not exists plan_nutrition jsonb;
alter table profiles add column if not exists plan_supplements jsonb;

alter table profiles enable row level security;

create or replace function is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

drop policy if exists "own profile" on profiles;
create policy "own profile select"
  on profiles for select
  using (auth.uid() = id);

drop policy if exists "own profile update" on profiles;
create policy "own profile update"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id and role = 'user');

drop policy if exists "admin all" on profiles;
create policy "admin all"
  on profiles for all
  using (is_admin())
  with check (is_admin());

create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.email)
  )
  on conflict (id) do update
  set email = excluded.email,
      full_name = excluded.full_name;
  return new;
exception when others then
  raise log 'handle_new_user error for %: %', new.id, sqlerrm;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
