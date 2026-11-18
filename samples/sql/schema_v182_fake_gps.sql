alter table app_settings add column if not exists allow_fake_gps boolean not null default false;

create or replace function public.report_fake_gps(p_kind text, p_detail text default null)
returns void language plpgsql security definer set search_path to 'public' as $$
declare nm text; r text;
begin
  if auth.uid() is null then return; end if;
  -- one alert per person per kind every 10 minutes
  if exists (select 1 from security_alerts where user_id = auth.uid() and kind = 'fake gps ' || coalesce(p_kind, 'mock') and created_at > now() - interval '10 minutes') then return; end if;
  select coalesce(nullif(btrim(full_name), ''), 'A driver'), role into nm, r from profiles where id = auth.uid();
  insert into security_alerts (kind, message, user_id)
  values ('fake gps ' || coalesce(p_kind, 'mock'),
          nm || case coalesce(p_kind, 'mock')
                  when 'jump' then ' moved impossibly fast between two GPS points' || coalesce(' (' || p_detail || ')', '') || '.'
                  else ' is using a fake (mock) location.' end,
          auth.uid());
end $$;
revoke all on function public.report_fake_gps(text, text) from public, anon;
grant execute on function public.report_fake_gps(text, text) to authenticated;
