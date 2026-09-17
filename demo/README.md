# Demo survey data

`public.survey_responses_demo` holds 98 synthetic responses for testing report
rendering at scale. The seed script is `seed_survey_responses_demo.sql`.

## Why it is a separate table

`public.survey_responses` holds real research data — 44 responses collected
16–17 Sep, including free-text answers in respondents' own words and 9 real
follow-up email addresses. Generated rows are never inserted there. Padding a
real sample with invented rows produces a report that describes nobody, and
once mixed the two are indistinguishable.

## What the demo data reproduces

Seeded to mirror the real set's structure so the report exercises the same
code paths, scaled from 44 to 98:

| path | status | blocks | real | demo |
| --- | --- | --- | --- | --- |
| single_man | completed | A,B,E,F | 13 | 29 |
| single_woman_dates_men | completed | A,B,C,D,F | 8 | 18 |
| taken_woman | completed | A,D,F | 8 | 18 |
| single_woman_dates_women | completed | A,B,D,F | 2 | 4 |
| taken_man | partner_redirect | A | 9 | 20 |
| screened_out | screened_out | A | 4 | 9 |

Answer-value weights approximate the real distributions, so charts land in a
realistic shape rather than uniform noise. Durations track the real per-path
averages (screen-outs ~5s, `single_woman_dates_women` ~650s).

**The distributions are approximate by construction. Do not read findings off
this table.** It exists to prove the report renders, not to tell you anything.

## Safety properties

- Every row has `is_synthetic = true`, so any export carrying them self-labels.
- Follow-up emails all use `@example.com` (RFC 2606 reserved, undeliverable).
- RLS on, admin-only `select`, no `anon` or plain `authenticated` access.
- `survey_report_demo(p_key)` mirrors `survey_report(p_key)` against this table,
  behind the same report key, and stamps `is_synthetic: true` on every record.

## Point the report at it

Swap the RPC name — `survey_report` → `survey_report_demo`. Same key, same
response shape, 98 rows instead of 44.

## Reset

```sql
truncate public.survey_responses_demo;
-- then re-run seed_survey_responses_demo.sql
```
