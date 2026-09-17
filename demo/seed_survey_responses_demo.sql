-- Seeds 98 synthetic rows into public.survey_responses_demo.
-- Idempotent only in the sense that you should TRUNCATE first; re-running appends.
-- SYNTHETIC DATA. See demo/README.md before using any of it for anything.

create or replace function private.demo_pick(vals text[])
returns text language sql volatile as
$$ select vals[1 + floor(random() * array_length(vals,1))::int] $$;

do $seed$
declare
  i int;
  v_path text; v_status text; v_gender text; v_rel text; v_int text;
  v_dur int; v_ans jsonb; v_f2 text; v_email text; v_created timestamptz;
  age   text[] := array['22–25','22–25','22–25','22–25','22–25','22–25','18–21','26–30','Over 30'];
  lik5  text[] := array['Strongly disagree','Disagree','Neutral','Neutral','Agree','Agree','Agree','Strongly agree'];
  freq  text[] := array['Never','Rarely','Rarely','Rarely','Sometimes','Sometimes','Often','Always'];
  money text[] := array['$0','$0','$0','$0','$0','$1–10','$1–10','$11–25','$26–50'];
  lk4   text[] := array['Very unlikely','Unlikely','Not sure','Not sure','Likely','Likely','Likely','Very likely'];
  apps  text[] := array['None','None','Hinge','Bumble','Tinder','Other'];
  d9    text[] := array['Nothing','Unsure he''s ready','Unsure he''s ready','Blame if it goes badly','Too much effort','His privacy'];
  e9    text[] := array['Nothing','Nothing','Friend''s opinion of me','Privacy','Embarrassment','Less control'];
  f1    text[] := array[
    'Apps feel transactional and I lose interest quickly.',
    'Hard to tell who is actually serious about meeting.',
    'Too much swiping, not enough real conversation.',
    'I would trust a friend''s recommendation far more than an algorithm.',
    'Most matches never turn into an actual conversation.',
    ''];
begin
  for i in 1..98 loop
    v_path := case
      when i <= 29 then 'single_man'
      when i <= 47 then 'single_woman_dates_men'
      when i <= 65 then 'taken_woman'
      when i <= 69 then 'single_woman_dates_women'
      when i <= 89 then 'taken_man'
      else 'screened_out' end;

    v_status := case v_path
      when 'taken_man' then 'partner_redirect'
      when 'screened_out' then 'screened_out'
      else 'completed' end;

    v_gender := case when v_path in ('single_man','taken_man') then 'Male'
                     when v_path = 'screened_out' then private.demo_pick(array['Male','Female',null])
                     else 'Female' end;
    v_rel := case when v_path in ('taken_man','taken_woman') then 'In a relationship'
                  when v_path = 'screened_out' then null
                  else private.demo_pick(array['Single','Single','Single','Dating casually']) end;
    v_int := case when v_path = 'single_man' then 'Women'
                  when v_path = 'single_woman_dates_men' then 'Men'
                  when v_path = 'single_woman_dates_women' then 'Women'
                  else null end;

    v_dur := case v_path
      when 'single_man' then 150 + floor(random()*140)::int
      when 'single_woman_dates_men' then 220 + floor(random()*200)::int
      when 'taken_woman' then 140 + floor(random()*130)::int
      when 'single_woman_dates_women' then 400 + floor(random()*500)::int
      when 'taken_man' then 8 + floor(random()*12)::int
      else 3 + floor(random()*5)::int end;

    v_ans := jsonb_build_object(
      'A1', private.demo_pick(age),
      'A2', v_gender,
      'A3', private.demo_pick(array['India','India','India','India','India','India','India','Other']),
      'A4', v_rel);
    if v_int is not null then v_ans := v_ans || jsonb_build_object('A5', v_int); end if;

    if v_path like 'single_%' then
      v_ans := v_ans || jsonb_build_object(
        'B1', (select jsonb_agg(distinct private.demo_pick(apps)) from generate_series(1,1+floor(random()*2)::int)),
        'B2', private.demo_pick(freq),
        'B3', private.demo_pick(array['No dates in 12 months','No dates in 12 months','Through friends','App','Work or school']),
        'B4', private.demo_pick(array['Strongly disagree','Disagree','Neutral','Neutral','Neutral','Agree']),
        'B5', private.demo_pick(array['Disagree','Neutral','Agree','Agree','Agree','Agree','Strongly agree']),
        'B6', private.demo_pick(lik5), 'B7', private.demo_pick(lik5),
        'B8', private.demo_pick(array['$0','$0','$0','$0','$0','$1–10','$11–25']));
    end if;

    if v_path = 'single_woman_dates_men' then
      v_ans := v_ans || jsonb_build_object(
        'C1', private.demo_pick(array['Sometimes','Often','Always','Always']),
        'C2', private.demo_pick(array['Sometimes','Often','Always']),
        'C3', private.demo_pick(array['Neutral','Neutral','Agree','Strongly agree']),
        'C4', private.demo_pick(array['Neutral','Neutral','Agree','Strongly agree']),
        'C5', private.demo_pick(array['Disagree','Neutral','Agree','Strongly agree']),
        'C6', private.demo_pick(array['Disagree','Neutral','Agree','Agree','Strongly agree']),
        'C7', private.demo_pick(lk4), 'C8', private.demo_pick(lk4),
        'C9', private.demo_pick(money));
    end if;

    if v_path in ('single_woman_dates_men','single_woman_dates_women','taken_woman') then
      v_ans := v_ans || jsonb_build_object(
        'D1', private.demo_pick(array['Disagree','Neutral','Agree','Agree','Agree','Strongly agree']),
        'D2', private.demo_pick(freq),
        'D3', private.demo_pick(array['Disagree','Neutral','Agree','Agree','Strongly agree']),
        'D4', private.demo_pick(array['Disagree','Neutral','Agree','Agree','Strongly agree']),
        'D5', private.demo_pick(array['0','1','1','2–3','2–3','4–5']),
        'D6', private.demo_pick(lik5),
        'D7', private.demo_pick(array['Disagree','Neutral','Agree','Agree','Agree','Strongly agree']),
        'D8', private.demo_pick(array['Neutral','Agree','Agree','Agree','Strongly agree']),
        'D9', (select jsonb_agg(distinct private.demo_pick(d9)) from generate_series(1,1+floor(random()*2)::int)),
        'D10', private.demo_pick(array['Unlikely','Not sure','Likely','Likely','Likely','Very likely']));
    end if;

    if v_path = 'single_man' then
      v_ans := v_ans || jsonb_build_object(
        'E1', private.demo_pick(array['0','0','1–2','1–2','3–5']),
        'E2', private.demo_pick(lik5), 'E3', private.demo_pick(lik5), 'E4', private.demo_pick(lik5),
        'E5', private.demo_pick(lik5), 'E6', private.demo_pick(lik5), 'E7', private.demo_pick(lik5),
        'E8', private.demo_pick(lik5),
        'E9', (select jsonb_agg(distinct private.demo_pick(e9)) from generate_series(1,1+floor(random()*2)::int)),
        'E10', private.demo_pick(lk4),
        'E11', private.demo_pick(array['Very unlikely','Unlikely','Not sure','Not sure','Not sure','Likely']),
        'E12', private.demo_pick(money));
    end if;

    v_email := null;
    if v_status = 'completed' then
      v_f2 := private.demo_pick(array['Yes','No','No']);
      v_ans := v_ans || jsonb_build_object('F1', private.demo_pick(f1), 'F2', v_f2);
      -- @example.com is RFC 2606 reserved and undeliverable
      if v_f2 = 'Yes' then v_email := 'demo+' || i || '@example.com'; end if;
    end if;

    v_created := now() - (random() * interval '14 days');

    insert into public.survey_responses_demo
      (created_at, status, age_band, gender, country, relationship,
       interested_in, path, answers, followup_email, duration_seconds)
    values
      (v_created, v_status, v_ans->>'A1', v_gender, v_ans->>'A3', v_rel,
       v_int, v_path, v_ans, v_email, v_dur);
  end loop;
end $seed$;
