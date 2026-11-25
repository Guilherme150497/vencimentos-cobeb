-- Vencimentos COBEB — tabela separada no Supabase (prefixo venc_)
-- Cole no SQL Editor e clique em Run.

create table if not exists public.venc_dados (
  path text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.venc_dados enable row level security;

-- Perfil do usuário logado (admin | editor | leitor), lido do cadastro em usuarios/<email>
create or replace function public.venc_perfil() returns text
language sql stable security definer set search_path = public as $$
  select data->>'perfil'
  from public.venc_dados
  where path = 'usuarios/' || regexp_replace(lower(coalesce(auth.jwt()->>'email','')), '[^a-z0-9]', '_', 'g')
    and coalesce(data->>'ativo','true') <> 'false'
$$;

drop policy if exists venc_select on public.venc_dados;
drop policy if exists venc_insert on public.venc_dados;
drop policy if exists venc_update on public.venc_dados;
drop policy if exists venc_delete on public.venc_dados;

create policy venc_select on public.venc_dados for select to authenticated
  using (public.venc_perfil() is not null);

create policy venc_insert on public.venc_dados for insert to authenticated
  with check ((path like 'usuarios/%' and public.venc_perfil() = 'admin')
           or (path not like 'usuarios/%' and public.venc_perfil() in ('admin','editor')));

create policy venc_update on public.venc_dados for update to authenticated
  using ((path like 'usuarios/%' and public.venc_perfil() = 'admin')
      or (path not like 'usuarios/%' and public.venc_perfil() in ('admin','editor')))
  with check ((path like 'usuarios/%' and public.venc_perfil() = 'admin')
      or (path not like 'usuarios/%' and public.venc_perfil() in ('admin','editor')));

create policy venc_delete on public.venc_dados for delete to authenticated
  using ((path like 'usuarios/%' and public.venc_perfil() = 'admin')
      or (path not like 'usuarios/%' and public.venc_perfil() in ('admin','editor')));

-- Tempo real
do $$ begin
  alter publication supabase_realtime add table public.venc_dados;
exception when duplicate_object then null; end $$;

-- Administrador principal
insert into public.venc_dados (path, data) values (
  'usuarios/guilherme_martins_cobeb_com_br',
  '{"email":"guilherme.martins@cobeb.com.br","nome":"Guilherme Martins","perfil":"admin","ativo":true}'::jsonb
) on conflict (path) do nothing;
