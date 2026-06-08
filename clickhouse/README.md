# ClickHouse — SEC EDGAR

ClickHouse schema + sink for the SEC EDGAR Substreams (`db_out`).

## Schema layers

Numbered prefixes enforce dependency order; `make schema` concatenates them
(sorted) into the single `schema.sql` the sink loads.

### Layer 0 — foundation (`schema.0.*`)
- `schema.0.blocks.sql` — `blocks` (EDGAR 10-minute windows).
- `schema.0.templates.sql` — `TEMPLATE_FILING` (one-per-filing envelope) and
  `TEMPLATE_FILING_CHILD` (repeated sub-records). Every table inherits one of
  these via `CREATE TABLE x AS TEMPLATE_...`.

### Layer 1 — filing tables (`schema.1.*`)
One file per form family. Header tables (one row per filing, keyed by
`accession_number`) inherit `TEMPLATE_FILING`; child tables (repeated records,
keyed by `accession_number, child_index`) inherit `TEMPLATE_FILING_CHILD`.

Raw event tables lead their `ORDER BY` with **`timestamp`** (time-series first):
`(timestamp, accession_number[, child_index])`. Still a unique dedup key — a
filing's acceptance window is fixed by its accession. The `filings` master adds
a `prj_accession` projection for point lookups by `accession_number`.

| File | Tables |
|------|--------|
| `schema.1.filings.sql`    | `filings` (master index), `raw_filings` |
| `schema.1.ownership.sql`  | `ownership_documents`, `reporting_owners`, `ownership_transactions`, `ownership_holdings`, `ownership_footnotes`, `ownership_signatures` |
| `schema.1.form13f.sql`    | `form13f_reports`, `form13f_other_managers`, `form13f_holdings` |
| `schema.1.beneficial.sql` | `beneficial_ownership_reports`, `beneficial_reporting_persons` |
| `schema.1.form144.sql`    | `form144_notices`, `form144_securities_to_be_sold`, `form144_securities_sold_past_3_months` |
| `schema.1.nport.sql`      | `nport_reports`, `nport_monthly_returns`, `nport_holdings` |
| `schema.1.formd.sql`      | `formd_notices`, `formd_related_persons` |
| `schema.1.npx.sql`        | `npx_reports`, `npx_votes`, `npx_vote_records` |
| `schema.1.ncen.sql`       | `ncen_reports` |
| `schema.1.formc.sql`      | `formc_notices` |

### Layer 2 — aggregate state (`schema.2.mv.*`)
Each file defines an `AggregatingMergeTree`/`SummingMergeTree` **state table** +
a **materialized view** that rolls raw rows into it on insert. Modelled on the
`data.sec.gov` API access patterns:

| State table | MV source | Rollup |
|---|---|---|
| `state_companies`          | `filings`                 | filer registry: latest name, form types, count, first/last |
| `state_insiders`           | `reporting_owners`        | owner registry: name, distinct issuers, role flags ever held |
| `state_institutions`       | `form13f_reports`         | 13F manager registry: name, latest portfolio value/period |
| `state_holdings_13f_latest`| `form13f_holdings`        | latest 13F position per (manager, cusip) — `argMax` over time |
| `state_insider_tx_daily`   | `ownership_transactions`  | insider trades per issuer/day/code: count, shares, notional |

### Layer 3 — read views (`schema.3.view.*`)
Plain views that `-Merge` / `GROUP BY` the state tables into final values —
query these, not the `state_*` tables: `companies`, `insiders`, `institutions`,
`holdings_13f_latest`, `insider_tx_daily`.

> MVs fire on **insert** to the source (pre-dedup). EDGAR is append-only so this
> is exact in practice; a replay of the same filing would double-count until you
> rebuild the state table.

## Conventions

- **Engine** — every table is `ReplacingMergeTree`, so re-streaming a window is
  idempotent (dedup on the sort key = natural key).
- **Keys** — header tables `ORDER BY (accession_number)`; child tables
  `ORDER BY (accession_number, child_index)`. Join child → header on
  `accession_number`; join either → `filings`/`blocks` for full envelope.
- **Numbers** — EDGAR reports amounts as raw XML strings, kept faithfully in the
  string column; a paired `<field>_num Float64` is added for analytics.
- **Repeated scalars** — short enumerations (relationships, exemptions, rule
  cites, footnote ids) are comma-joined into one `String`; query with
  `has(splitByChar(',', col), 'X')`.
- **Time** — `timestamp` is the window start (acceptance bucket);
  `acceptance_datetime` is the per-filing acceptance time.

## Run

This directory is **plain SQL** — there's no sub-package here. The sink config
lives in the repo-root `substreams.yaml` (`sink:` block → `./clickhouse/schema.sql`),
and the root `Makefile` drives everything. From the repo root:

```bash
# regenerate clickhouse/schema.sql from the numbered layers (also run by `pack`)
make schema

# 1. create tables (once)
make setup DSN=clickhouse://default:@localhost:9000/default

# 2. stream filings
make dev DSN=clickhouse://default:@localhost:9000/default \
         ENDPOINT=sec.substreams.pinax.network:443 \
         START_BLOCK=2953156 STOP_BLOCK=+1000
```

`make pack` rebuilds the wasm, regenerates `schema.sql`, and packs the single
`sec-v0.3.0.spkg` (db_out + sink + schema).
