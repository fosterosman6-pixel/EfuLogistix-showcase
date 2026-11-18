-- EfuLogistix: database update v183
--   The office can CLOSE a chat; the person can then start a new one (asks for a chat) and the office sees the request.
--   * office_chat_state: one row per person; closed_at set = closed
--   * the person can write only while the chat is open (office wrote and it is not closed, or the person requested it)
--   * a message from the office opens it again

create table if not exists public.office_chat_state (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  closed_at timestamptz,
  closed_by uuid references public.profiles (id) on delete set null,
  requested_at timestamptz
);
alter table public.office_chat_state enable row level security;
drop policy if exists ocs_read on public.office_chat_state;
create policy ocs_read on public.office_chat_state for select to authenticated using (user_id = auth.uid() or is_owner());

create or replace function public.send_office_chat(p_user uuid, p_body text, p_kind text default 'text', p_path text default null, p_seconds int default null)
returns void language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); staff boolean; target uuid; body text := btrim(coalesce(p_body, '')); rcpt uuid; who text; mgr boolean; myrole text; st record;
begin
  if me is null then raise exception 'not allowed' using errcode = '42501'; end if;
  if p_kind not in ('text', 'photo', 'voice') then raise exception 'BAD_MESSAGE'; end if;
  if p_kind = 'text' and (length(body) < 1 or length(body) > 1000) then raise exception 'BAD_MESSAGE'; end if;
  if p_kind <> 'text' and (p_path is null or split_part(p_path, '/', 1) <> me::text) then raise exception 'BAD_MESSAGE'; end if;
  if (select count(*) from chat_messages where sender_id = me and created_at > now() - interval '1 minute') >= 20 then raise exception 'SLOW_DOWN'; end if;
  staff := is_owner();
  select role into myrole from profiles where id = me;
  select office_chat_managers into mgr from app_settings where id = 1;
  if staff then
    if myrole = 'manager' and not coalesce(mgr, true) then raise exception 'not allowed' using errcode = '42501'; end if;
    if p_user is null or not exists (select 1 from profiles where id = p_user and role in ('driver', 'owner', 'passenger')) then raise exception 'not allowed' using errcode = '42501'; end if;
    target := p_user; rcpt := p_user;
    who := 'Office';
    insert into office_chat_state (user_id, closed_at, closed_by) values (target, null, null)
      on conflict (user_id) do update set closed_at = null, closed_by = null;
  else
    select * into st from office_chat_state where user_id = me;
    if st.user_id is not null then
      if st.closed_at is not null then raise exception 'CHAT_CLOSED'; end if;
    elsif not exists (select 1 from chat_messages where office_user = me and sender_id <> me) then
      raise exception 'not allowed' using errcode = '42501';
    end if;
    target := me;
    select sender_id into rcpt from chat_messages where office_user = me and sender_id <> me order by created_at desc limit 1;
    rcpt := coalesce(rcpt, me);
    who := coalesce((select nullif(btrim(full_name), '') from profiles where id = me), 'Someone');
  end if;
  insert into chat_messages (office_user, sender_id, recipient_id, kind, body, file_path, seconds)
  values (target, me, rcpt, p_kind, case when p_kind = 'text' then body else '' end, p_path, p_seconds);
  if staff then
    perform notify(target, 'Message from the office', case p_kind when 'photo' then '📷 Photo' when 'voice' then '🎤 Voice note' else left(body, 120) end, 'chat_office', me);
    insert into activity_log (actor, actor_name, action, table_name, row_id, detail)
    values (me, my_name(), 'office_chat', 'profiles', target::text, jsonb_build_object('kind', p_kind));
  else
    perform _notify_office('Reply from ' || who, case p_kind when 'photo' then '📷 Photo' when 'voice' then '🎤 Voice note' else left(body, 120) end, 'chat_office');
  end if;
end $$;
revoke all on function public.send_office_chat(uuid, text, text, text, int) from public, anon;
grant execute on function public.send_office_chat(uuid, text, text, text, int) to authenticated;

-- office: close one person's chat
create or replace function public.close_office_chat(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_owner() then raise exception 'not allowed' using errcode = '42501'; end if;
  insert into office_chat_state (user_id, closed_at, closed_by) values (p_user, now(), auth.uid())
    on conflict (user_id) do update set closed_at = now(), closed_by = auth.uid();
  insert into activity_log (actor, actor_name, action, table_name, row_id, detail)
  values (auth.uid(), my_name(), 'office_chat_close', 'profiles', p_user::text, '{}'::jsonb);
end $$;
revoke all on function public.close_office_chat(uuid) from public, anon;
grant execute on function public.close_office_chat(uuid) to authenticated;

-- person: ask the office for a chat (starts a new one, or opens a closed one)
create or replace function public.request_office_chat(p_body text) returns void
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); body text := btrim(coalesce(p_body, '')); who text; last_req timestamptz;
begin
  if me is null or is_owner() then raise exception 'not allowed' using errcode = '42501'; end if;
  if length(body) < 1 or length(body) > 1000 then raise exception 'BAD_MESSAGE'; end if;
  select requested_at into last_req from office_chat_state where user_id = me;
  if last_req is not null and last_req > now() - interval '1 minute' then raise exception 'SLOW_DOWN'; end if;
  who := coalesce((select nullif(btrim(full_name), '') from profiles where id = me), 'Someone');
  insert into office_chat_state (user_id, closed_at, closed_by, requested_at) values (me, null, null, now())
    on conflict (user_id) do update set closed_at = null, closed_by = null, requested_at = now();
  insert into chat_messages (office_user, sender_id, recipient_id, kind, body) values (me, me, me, 'text', body);
  perform _notify_office('Chat request from ' || who, left(body, 120), 'chat_office');
end $$;
revoke all on function public.request_office_chat(text) from public, anon;
grant execute on function public.request_office_chat(text) to authenticated;

notify pgrst, 'reload schema';
select 'ok' as result;
