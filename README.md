# Healthcare ELT Pipeline

An ELT pipeline built on [Synthea](https://synthetichealth.github.io/synthea/) synthetic patient data, modelling clinical encounters into a dimensional warehouse with automated data quality testing and CI.

**Stack:** Snowflake · dbt · GitHub Actions · Python

---

## Architecture

```
Synthea CSVs
     │
     ▼
  RAW  ──────────────  Untouched source data. Never queried directly.
     │
     ▼  dbt: rename + cast only
 STAGING  ───────────  18 views, 1:1 with source tables.
     │
     ▼  dbt: reshape for analysis
  MARTS  ────────────  Star schema. 6 tables.
```

**RAW**: The landing zone. Nothing writes to it, nothing changes it. It's the thing every downstream error can be rebuilt from.

**STAGING**: One view per source table. Columns renamed to a consistent convention and cast to correct types. No business logic, no joins, no null handling. Materialised as **views** because they're cheap, always fresh, and never queried by end users.

**MARTS**: The analyst-facing product. The source's shape is replaced with a shape built for questions. Materialised as **tables**: compute once at build time, fast reads forever.

---

## The star schema

```
                    dim_patients
                         │
  dim_payers ────── fct_encounters ────── dim_providers
                    ╱         ╲
     dim_encounter_codes    dim_organizations
```

| Model | Grain | Rows |
|---|---|---|
| `fct_encounters` | one row per clinical encounter | 79,142 |
| `dim_patients` | one row per patient | 1,229 |
| `dim_providers` | one row per provider | 840 |
| `dim_organizations` | one row per organization | 840 |
| `dim_encounter_codes` | one row per distinct encounter code | 56 |
| `dim_payers` | one row per payer | 10 |

The "fact" table holds **measures** (costs) and **foreign keys**. The dimensions hold **attributes**, the things that are noramlly filtered and grouped by.

The test that decides which is which: *would you `SUM()` it, or `GROUP BY` it?*

---

## Design decisions

### Type honesty

Synthea mixes temporal precision. Some columns are date-only (`2016-02-20`); others are full ISO timestamps with a UTC offset (`2016-02-20T18:37:36Z`). Every temporal column was queried against the raw data before being cast.

| Cast as `DATE` | Cast as `TIMESTAMP_TZ` |
|---|---|
| allergies, conditions, supplies, careplans | encounters, medications, procedures, observations, immunizations, devices, imaging studies, payer transitions, claims |

Casting a date-only value to a timestamp invents a `00:00:00` that doesn't exist in the source. Downstream, "unknown time" becomes indistinguishable from "actually midnight," and any duration calculated against a real timestamp is silently wrong by up to a day.

**Column names must not lie about their type.** `_date` for `DATE`, `_timestamp` for `TIMESTAMP_TZ`. A column called `encounter_date` invites an analyst to `GROUP BY` it expecting one row per day; if it's secretly a timestamp, they get one row per second.

### Money as `DECIMAL`, not `FLOAT`

Binary floating point cannot represent decimal cents exactly. Aggregate enough of them and you get drift. All cost columns are `DECIMAL(12,2)`.

### Clinical codes stay `VARCHAR`

SNOMED and RxNorm codes look numeric but are identifiers, not quantities. You never do arithmetic on them, and casting to a number risks stripping leading zeros.

### `dim_encounter_codes` earned a table; `encounter_class` didn't

`code` and `description` were repeated across all 79,142 encounter rows, but there are only **56 distinct codes**. Promoting them to a dimension:

- deduplicates a long description string stored ~1,400 times over
- creates a single source of truth for the code → description mapping, enforced by a `unique` test
- gives future code attributes (category, chargeable flag) somewhere to live

`encounter_class` has 10 short values, no description to deduplicate, and no attributes to hang off it. It stays on the fact table as a **degenerate dimension** which is a dimensional attribute that lives on the fact because promoting it would buy nothing.

### Surrogate keys

The fact table joins to dimensions on hashed surrogate keys (`dbt_utils.generate_surrogate_key`), not natural keys.

A fact row points at a *row in a dimension*, not at a real-world entity. Today those are the same thing. Once slowly-changing dimensions are added, in the event of something like a patient moving city, the old dim row is kept and a new one added. That means one `patient_id` maps to two dim rows, and only the surrogate key can tell them apart.

The keys are **deterministic hashes**, not auto-increment integers, because models are rebuilt from scratch on every run and an auto-increment would hand out different numbers each time.

### `LEFT JOIN`, never `INNER JOIN`

An inner join would silently *drop* any encounter whose payer didn't exist in `dim_payers`. The row count would just be quietly smaller and nothing would say so.

A left join keeps every encounter and leaves a `NULL` surrogate key, which the `not_null` test then catches as a build failure.

**A join must never be allowed to silently delete facts.**

### Dimensions hold attributes, never measures

`payers.revenue`, `providers.encounters`, `organizations.utilization` were all dropped from the marts. They are pre-aggregated totals that `fct_encounters` can compute itself.

Storing a number someone else summed means losing the ability to slice it differently, and it creates two sources of truth that can eventually disagree.

### PII does not reach the marts

`ssn`, `passport`, `drivers`, and address-level detail are dropped at the marts boundary. Staging mirrors the source faithfully; the analyst-facing layer does not need them, and in healthcare that is a compliance question, not a style preference.

---

## Data quality

**31 tests**, run on every build and on every pull request.

| Test | What it guarantees |
|---|---|
| `unique` on every dimension surrogate key | **The fact table cannot fan out.** A duplicate key in a dim is what would silently turn 79,142 encounters into 200,000. |
| `not_null` on every foreign key in the fact | **The fact table cannot have orphans.** With `LEFT JOIN`, an unmatched dimension leaves a `NULL`, and this turns that into a loud failure. |
| `relationships` | Every surrogate key in the fact resolves to a real dimension row. Snowflake does not enforce foreign keys; this is the only thing that does. |
| `accepted_values` | Value domains verified against `SELECT DISTINCT` on the actual data, never guessed. |

Together, these mean **the fact table cannot gain or lose rows without the build going red.**

Every model is built with `dbt build`, never `dbt run`. `build` interleaves running and testing, so a model that fails its tests blocks its children from being built on bad data.

---

## Security

- **Least-privilege role.** dbt runs as a `TRANSFORMER` role with `SELECT` on `RAW` and `CREATE SCHEMA` on the database. Nothing else. It is verified to be unable to write to `RAW`.
- **Service account.** A dedicated `DBT_USER` with key-pair authentication, separate from any human user, so credentials can be rotated without locking anyone out and the audit log distinguishes pipeline queries from interactive ones.
- **No secrets in the repository.** `profiles.yml` is committed and contains only `env_var()` references. Credentials live in GitHub Secrets, are injected as environment variables at runtime, and are masked in logs.

---

## CI

`.github/workflows/dbt_ci.yml` runs on every pull request against `main`:

1. Fresh Ubuntu container
2. `pip install dbt-snowflake`
3. `dbt deps`
4. `dbt build --target ci`, covering all 24 models and all 31 tests, against a dedicated `CI_*` schema isolated from dev

A non-zero exit blocks the merge. The tests are not advisory; they are a gate.

---

## Running it locally

```bash
cd healthcare_dbt
dbt deps
dbt build
```

Requires `DBT_PRIVATE_KEY_PATH` set to the path of your Snowflake private key.

---

## Roadmap

- [ ] **Orchestration**: Airflow/Dagster DAG wrapping the dbt build on a schedule
- [ ] **Ingestion**: Python loader for Synthea CSVs into `RAW`, replacing the manual load
- [ ] **Slim CI**: `state:modified+` so PRs rebuild only what changed and its downstream children
- [ ] **Slowly-changing dimensions**: Type 2 history on `payer_transitions`, so a 2016 claim attributes to the payer the patient had *then*
