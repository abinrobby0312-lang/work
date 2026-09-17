-- Synthetic survey data for testing report rendering at ~100 rows.
-- Applied to Supabase project ooipifeiymybepdbsufe on 2026-09-17.
--
-- Deliberately a SEPARATE table. public.survey_responses holds 44 real
-- respondent answers (real free text, real follow-up emails). Generated rows
-- must never be mixed into it: any analysis drawn from the combined set would
-- describe nobody, and there is no way to unpick them afterwards.

create table if not exists public.survey_responses_demo (
  id               uuid primary key default gen_random_uuid(),
  created_at       timestamptz not null default now(),
  status           text not null,
  age_band         text,
  gender           text,
  country          text,
  relationship     text,
  interested_in    text,
  path             text,
  answers          jsonb not null,
  followup_email   text,
  duration_seconds integer,
  is_synthetic     boolean not null default true
);

comment on table public.survey_responses_demo is
  'SYNTHETIC DATA ONLY. Generated to exercise report rendering at scale. Not real respondents; never merge into public.survey_responses or report as research findings.';

alter table public.survey_responses_demo enable row level security;

drop policy if exists survey_demo_select_admin on public.survey_responses_demo;
create policy survey_demo_select_admin on public.survey_responses_demo
  for select to authenticated
  using (private.is_admin(auth.uid()));

create or replace function public.survey_report_demo(p_key text)
returns jsonb language plpgsql security definer set search_path to ''
as $function$
declare v_ok boolean;
begin
  select exists (
    select 1 from private.report_access
    where key_hash = encode(extensions.digest(coalesce(p_key, ''), 'sha256'), 'hex')
  ) into v_ok;
  if not v_ok then raise exception 'invalid report key' using errcode = '28000'; end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'created_at', r.created_at, 'status', r.status, 'path', r.path,
      'age_band', r.age_band, 'gender', r.gender, 'country', r.country,
      'relationship', r.relationship, 'interested_in', r.interested_in,
      'duration_seconds', r.duration_seconds,
      'has_email', r.followup_email is not null,
      'is_synthetic', true,
      'answers', r.answers
    ) order by r.created_at)
    from public.survey_responses_demo r
  ), '[]'::jsonb);
end;
$function$;

revoke execute on function public.survey_report_demo(text) from anon;
