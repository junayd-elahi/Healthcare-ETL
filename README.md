# Healthcare ELT Pipeline

An end-to-end ELT pipeline built on [Synthea](https://synthetichealth.github.io/synthea/) synthetic patient data, modelling clinical encounters and medications into a dimensional warehouse with automated data quality testing, CI, and scheduled orchestration.

**Stack:** Snowflake · dbt · Airflow · Docker · GitHub Actions · Python

---

## Architecture

```
Synthea CSVs
     │
     ▼  Python loader
  RAW  ──────────────  Untouched source data, all VARCHAR. Never queried directly.
     │
     ▼  dbt: rename + cast only
 STAGING  ───────────  18 views, 1:1 with source tables.
     │
     ▼  dbt: reshape for analysis
  MARTS  ────────────  Dimensional model. 2 facts, 6 dimensions.
```
![Lineage graph](docs/etl%20healthcare%20graph.png)

Three layers, each with exactly one job.

**RAW** is the landing zone. Every column is `VARCHAR`. Nothing writes to it, nothing changes it, and it enforces no types. A malformed value in a future source file should land in RAW and fail a test downstream, not crash the ingestion at 3am.

**STAGING** is one view per source table. Columns renamed to a consistent convention and cast to correct types. No business logic, no joins, no null handling. Materialised as **views** because they are cheap, always fresh, and never queried by end users.

**MARTS** is the analyst-facing product. The source's shape is replaced with a shape built for questions. Materialised as **tables**: compute once at build time, fast reads forever.

---

## The dimensional model

Two fact tables sharing **conformed dimensions**.

| Model | Grain | Rows |
|---|---|---|
| `fct_encounters` | one row per clinical encounter | 79,142 |
| `fct_medications` | one row per medication prescribed | 78,009 |
| `dim_patients` | one row per patient | 1,229 |
| `dim_providers` | one row per provider | 840 |
| `dim_organizations` | one row per organization | 840 |
| `dim_medication_codes` | one row per distinct medication code | 262 |
| `dim_encounter_codes` | one row per distinct encounter code | 56 |
| `dim_payers` | one row per payer | 10 |

Fact tables hold **measures** (costs, quantities) and **foreign keys**. Dimensions hold **attributes**, the things you filter and group by.

The test that decides which is which: *would you `SUM()` it, or `GROUP BY` it?*

`dim_patients` and `dim_payers` are **conformed**: both facts point at the same rows. That is what makes "total spend per patient across encounters and medications" a question that reconciles, rather than one that produces two numbers nobody trusts.

---

## Design decisions

### Type honesty

Synthea mixes temporal precision. Some columns are date-only (`2016-02-20`); others are full ISO timestamps with a UTC offset (`2016-02-20T18:37:36Z`). Every temporal column was queried against the raw data before being cast.

| Cast as `DATE` | Cast as `TIMESTAMP_TZ` |
|---|---|
| allergies, conditions, supplies, careplans | encounters, medications, procedures, observations, immunizations, devices, imaging studies, payer transitions, claims |

Casting a date-only value to a timestamp invents a `00:00:00` that does not exist in the source. Downstream, "unknown time" becomes indistinguishable from "actually midnight," and any duration calculated against a real timestamp is silently wrong by up to a day.

**Column names must not lie about their type.** `_date` for `DATE`, `_timestamp` for `TIMESTAMP_TZ`. A column called `encounter_date` invites an analyst to `GROUP BY` it expecting one row per day; if it is secretly a timestamp, they get one row per second.

### Money as `DECIMAL`, not `FLOAT`

Binary floating point cannot represent decimal cents exactly. Aggregate enough of them and you get drift. All cost columns are `DECIMAL(12,2)`.

### Clinical codes stay `VARCHAR`

SNOMED and RxNorm codes look numeric but are identifiers, not quantities. You never do arithmetic on them, and casting to a number risks stripping leading zeros.

### Code dimensions earned their tables; `encounter_class` did not

`code` and `description` were repeated across all 79,142 encounter rows, but there are only **56 distinct codes**. Same story for medications: 78,009 rows, 262 codes. Promoting them to dimensions:

- deduplicates a long description string stored hundreds of times over
- creates a single source of truth for the code to description mapping, enforced by a `unique` test
- gives future code attributes (category, chargeable flag) somewhere to live

`encounter_class` has 10 short values, no description to deduplicate, and no attributes to hang off it. It stays on the fact table as a **degenerate dimension**: a dimensional attribute that lives on the fact because promoting it would buy nothing.

`fct_medications` carries `encounter_id` as a degenerate dimension rather than joining to an encounter dimension. A conformed `dim_encounters` was considered and rejected: its descriptive attributes are already reachable from `fct_encounters`, and facts should not join to facts.

### Surrogate keys

Fact tables join to dimensions on hashed surrogate keys (`dbt_utils.generate_surrogate_key`), not natural keys.

A fact row points at a *row in a dimension*, not at a real-world entity. Today those are the same thing. Once slowly-changing dimensions are added, in the event of something like a patient moving city, the old dim row is kept and a new one added. That means one `patient_id` maps to two dim rows, and only the surrogate key can tell them apart.

The keys are **deterministic hashes**, not auto-increment integers, because models are rebuilt from scratch on every run and an auto-increment would hand out different numbers each time.

### `LEFT JOIN`, never `INNER JOIN`

An inner join would silently *drop* any encounter whose payer did not exist in `dim_payers`. The row count would just be quietly smaller and nothing would say so.

A left join keeps every row and leaves a `NULL` surrogate key, which the `not_null` test then catches as a build failure.

**A join must never be allowed to silently delete facts.**

### Dimensions hold attributes, never measures

`payers.revenue`, `providers.encounters`, `organizations.utilization` were all dropped from the marts. They are pre-aggregated totals that the fact tables can compute themselves.

Storing a number someone else summed means losing the ability to slice it differently, and it creates two sources of truth that can eventually disagree.

### PII does not reach the marts

`ssn`, `passport`, `drivers`, and address-level detail are dropped at the marts boundary. Staging mirrors the source faithfully; the analyst-facing layer does not need them, and in healthcare that is a compliance question, not a style preference.

---

## A real bug: fanout in `fct_medications`

`fct_medications` first built at **85,337 rows** against a staging count of 78,009. A gain of 7,328 rows, and the build reported success, because the model had no tests yet.

**Cause.** `dim_medication_codes` was built with `SELECT DISTINCT code, description`. RxNorm is inconsistent about capitalisation: `Simvastatin 20 MG Oral Tablet` and `simvastatin 20 MG Oral Tablet` are the same drug under the same code. Thirteen codes appeared with two descriptions each, so the dimension held 275 rows for 262 codes. Every medication carrying one of those codes matched two dimension rows, and the join duplicated it.

**Fix.** Deduplicate on the key, not on the pair:

```sql
qualify row_number() over (
    partition by code
    order by description
) = 1
```

The `order by` is not cosmetic. Without it, Snowflake picks arbitrarily and the same build could produce a different description tomorrow.

**Prevention.** A `unique` test on `medication_code_sk` now fails the build if the dimension ever gains a duplicate key. That single test is the difference between catching this at build time and shipping a fact table that is 9% wrong.

---

## Data quality

**39 tests**, run on every build and on every pull request.

| Test | What it guarantees |
|---|---|
| `unique` on every dimension surrogate key | **Fact tables cannot fan out.** A duplicate key in a dimension is what silently turned 78,009 medications into 85,337. |
| `not_null` on every foreign key in a fact | **Fact tables cannot have orphans.** With `LEFT JOIN`, an unmatched dimension leaves a `NULL`, and this turns that into a loud failure. |
| `relationships` | Every surrogate key in a fact resolves to a real dimension row. Snowflake does not enforce foreign keys; this is the only thing that does. |
| `accepted_values` | Value domains verified against `SELECT DISTINCT` on the actual data, never guessed. |

Together, these mean **a fact table cannot gain or lose rows without the build going red.**

Every model is built with `dbt build`, never `dbt run`. `build` interleaves running and testing, so a model that fails its tests blocks its children from being built on bad data.

### A known gap

`fct_medications` has no `unique` test on a primary key, because **Synthea's medications table has no primary key**. Neither do allergies, conditions, procedures, observations, devices, supplies, or immunizations. There is no natural key and no reliable composite one. This is documented rather than papered over with a synthetic key that would give false confidence.

---

## Orchestration

An Airflow DAG (`airflow/dags/dbt_pipeline.py`) runs the pipeline end to end on a daily schedule, in Docker:

```
load_raw  →  dbt deps  →  dbt build
```

If the load fails, dbt never runs.

**Airflow calls dbt; it does not replace it.** dbt already knows the dependency order of all 26 models. Exploding each model into its own Airflow task would duplicate that graph and leave two dependency graphs to maintain. Airflow's job is scheduling, retries, and alerting.

`catchup=False` is set deliberately. Airflow's default is to backfill every missed interval since `start_date` the moment it boots, which is a fast way to burn warehouse credits on runs nobody asked for.

**Known shortcut:** Python dependencies are pip-installed inside the task rather than baked into the image. In production this belongs in a custom Dockerfile with a `requirements.txt`.

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
4. `dbt build --target ci`, covering all 26 models and all 39 tests, against a dedicated `CI_*` schema isolated from dev

A non-zero exit blocks the merge. The tests are not advisory; they are a gate.

On its first run, CI caught a hyphenated package name in `packages.yml` that a locally cached `dbt_packages/` folder had been masking.

---

## Running it locally

```bash
# Load raw data
cd ingestion
python load_raw.py

# Build and test the warehouse
cd ../healthcare_dbt
dbt deps
dbt build

# Or run the whole thing on a schedule
cd ../airflow
docker compose up
```

Requires `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `DBT_PRIVATE_KEY_PATH`, and `CSV_DIR` in a `.env` at the repo root.

---

## Roadmap

- [ ] **More fact tables.** Procedures, observations, conditions, and immunizations are all event tables with staging models built and no facts yet. Each is a new star on the existing conformed dimensions.
- [ ] **Slowly-changing dimensions.** Type 2 history on `payer_transitions`, so a 2016 claim attributes to the payer the patient had *then*, not the one they have now.
- [ ] **Slim CI.** `state:modified+` so pull requests rebuild only what changed and its downstream children.
- [ ] **Bake dependencies into the Airflow image** rather than pip-installing per task.
