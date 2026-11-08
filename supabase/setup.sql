-- StudiCockpit: Einrichtung der Synchronisierung in Supabase
-- Einmal im SQL Editor des Supabase-Projekts ausführen (alles markieren → Run).
-- Kann gefahrlos mehrfach ausgeführt werden.
--
-- Sicherheitsprinzip: Die Tabelle ist für die App nicht direkt lesbar oder schreibbar.
-- Zugriff gibt es nur über die drei Funktionen unten, und nur mit dem richtigen Sync-Code.
-- Gespeichert wird nur ein Hash des Codes, nie der Code selbst.

create table if not exists public.sync_state (
  id_hash    text primary key,
  data       jsonb not null,
  version    bigint not null default 1,
  updated_at timestamptz not null default now()
);

alter table public.sync_state enable row level security;
revoke all on table public.sync_state from anon, authenticated;

-- Stand abrufen: liefert {data, version, updated_at} oder null, wenn der Code unbekannt ist
create or replace function public.sync_get(code text)
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object('data', s.data, 'version', s.version, 'updated_at', s.updated_at)
  from public.sync_state s
  where length(code) >= 24
    and s.id_hash = encode(sha256(convert_to(code, 'UTF8')), 'hex');
$$;

-- Stand speichern: nur wenn base_version zum Server passt (sonst {ok:false, conflict:true}).
-- Ein neuer Code darf nur angelegt werden, solange es noch keinen gibt (ein Nutzer pro Projekt).
create or replace function public.sync_put(code text, new_data jsonb, base_version bigint default null)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  h   text;
  cur bigint;
begin
  if code is null or length(code) < 24 then
    raise exception 'code_zu_kurz';
  end if;
  if new_data is null or jsonb_typeof(new_data) <> 'object' then
    raise exception 'daten_ungueltig';
  end if;
  if pg_column_size(new_data) > 2000000 then
    raise exception 'daten_zu_gross';
  end if;

  h := encode(sha256(convert_to(code, 'UTF8')), 'hex');
  select s.version into cur from public.sync_state s where s.id_hash = h for update;

  if cur is null then
    if exists (select 1 from public.sync_state) then
      raise exception 'nur_ein_code';
    end if;
    insert into public.sync_state (id_hash, data, version) values (h, new_data, 1);
    return json_build_object('ok', true, 'version', 1);
  end if;

  if base_version is distinct from cur then
    return json_build_object('ok', false, 'conflict', true, 'version', cur);
  end if;

  update public.sync_state
     set data = new_data, version = cur + 1, updated_at = now()
   where id_hash = h;
  return json_build_object('ok', true, 'version', cur + 1);
end;
$$;

-- Für das tägliche Wachhalten (GitHub Actions), damit das kostenlose Projekt nicht pausiert
create or replace function public.ping()
returns integer
language sql
security definer
set search_path = public
as $$ select count(*)::integer from public.sync_state; $$;

revoke all on function public.sync_get(text) from public;
revoke all on function public.sync_put(text, jsonb, bigint) from public;
revoke all on function public.ping() from public;
grant execute on function public.sync_get(text) to anon, authenticated;
grant execute on function public.sync_put(text, jsonb, bigint) to anon, authenticated;
grant execute on function public.ping() to anon, authenticated;

-- PostgREST die neuen Funktionen bekannt machen
notify pgrst, 'reload schema';
