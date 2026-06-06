# substreams-sec

[Substreams](https://substreams.streamingfast.io) for **SEC EDGAR** filings.

Consumes the Firehose `pinax.sec.v1.Block` stream produced by
[`firehose-sec`](https://github.com/pinax-network/firehose-sec) and flattens
every structured disclosure form into relational rows for a **ClickHouse** sink
(`db_out`). Structured the same way as
[`substreams-hypercore`](https://github.com/pinax-network/substreams-hypercore).

> EDGAR has no native block concept. `firehose-sec` packages filings into
> 10-minute windows (`block_number = epoch bucket = unix_seconds / 600`),
> bucketed by acceptance time, so they stream like any other chain.

## Forms covered

Every body of the `pinax.sec.v1` schema:

| Form | Body | Tables |
|------|------|--------|
| 3 / 4 / 5      | Section 16 insider ownership      | `ownership_documents`, `reporting_owners`, `ownership_transactions`, `ownership_holdings`, `ownership_footnotes`, `ownership_signatures` |
| 13F-HR / 13F-NT | Institutional manager holdings   | `form13f_reports`, `form13f_other_managers`, `form13f_holdings` |
| SC 13D / 13G   | >5% beneficial ownership          | `beneficial_ownership_reports`, `beneficial_reporting_persons` |
| 144            | Proposed sale of restricted stock | `form144_notices`, `form144_securities_to_be_sold`, `form144_securities_sold_past_3_months` |
| N-PORT         | Fund portfolio holdings           | `nport_reports`, `nport_monthly_returns`, `nport_holdings` |
| D              | Exempt offering (Reg D)           | `formd_notices`, `formd_related_persons` |
| N-PX           | Proxy-voting record               | `npx_reports`, `npx_votes`, `npx_vote_records` |
| N-CEN          | Fund annual census                | `ncen_reports` |
| C              | Crowdfunding offering             | `formc_notices` |
| —              | Unparsed / legacy                 | `raw_filings` |

Plus the cross-form `filings` master index (one row per filing) and `blocks`
(the 10-minute windows). **27 tables.**

## Layout

```
substreams-sec/
├── substreams.yaml          # db_out: Clock + pinax.sec.v1.Block -> DatabaseChanges
├── Cargo.toml / Makefile
├── src/
│   ├── lib.rs               # db_out handler + shared helpers
│   ├── filings.rs           # master index + raw
│   ├── ownership.rs ...     # one module per form
│   └── pb/                  # generated from the schema spkg (make protogen)
├── spkg/                    # schema spkg + sink deps + packed .spkg
└── clickhouse/
    ├── substreams.yaml      # sql sink (engine: clickhouse)
    ├── Makefile             # schema concat + setup/dev
    ├── schema.0.*.sql       # blocks + TEMPLATE_FILING / TEMPLATE_FILING_CHILD
    └── schema.1.*.sql       # one file per form family
```

## Design

- **Keys** — every table keys off the globally-unique EDGAR `accession_number`.
  Header tables `ORDER BY (accession_number)`; child tables (repeated records)
  `ORDER BY (accession_number, child_index)`. All `ReplacingMergeTree`, so
  re-streaming a window is idempotent.
- **Envelope** — `TEMPLATE_FILING` (full filing envelope) and
  `TEMPLATE_FILING_CHILD` (lean envelope + position) are inherited via
  `CREATE TABLE x AS TEMPLATE_...`; both carry block metadata so any table is
  time-filterable without a join.
- **Numbers** — amounts stay faithful to the raw XML string; a paired
  `<field>_num Float64` is added for analytics. Repeated scalars are
  comma-joined into one `String`.

## Build & run

```bash
# build wasm + pack the substreams
make                       # = make pack -> spkg/sec-v0.1.0.spkg

# (re)generate src/pb from proto
make protogen

# stream into ClickHouse
cd clickhouse
make setup DSN=clickhouse://default:@localhost:9000/default        # create tables once
make dev   DSN=clickhouse://default:@localhost:9000/default \
           ENDPOINT=sec.substreams.pinax.network:443 \
           START_BLOCK=2953156 STOP_BLOCK=+1000
```

> `ENDPOINT` is the Pinax `sec` Substreams tier-1 — set it to your deployment.
> `START_BLOCK 2953156` is the first streamable `sec` block.

## Protobuf

The `pinax.sec.v1` schema is **not vendored** — it's imported as a proto-only
spkg published by
[`firehose-sec`](https://github.com/pinax-network/firehose-sec) (its
`substreams.yaml` declares the schema, the same shape as
[`substreams-evm/proto`](https://github.com/pinax-network/substreams-evm/tree/main/proto)).

```bash
# in firehose-sec: pack the schema and attach to a release
substreams pack -o sec-v0.3.0.spkg substreams.yaml
gh release upload v0.3.0 sec-v0.3.0.spkg

# here: regenerate src/pb straight from that spkg (local path or release URL)
make protogen SCHEMA_SPKG=./spkg/sec-v0.3.0.spkg
make protogen SCHEMA_SPKG=https://github.com/pinax-network/firehose-sec/releases/download/v0.3.0/sec-v0.3.0.spkg
```

`substreams.yaml` imports the same spkg (`imports.sec`), so `pinax.sec.v1.Block`
resolves as the `db_out` source without any local `.proto`.
