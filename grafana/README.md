# Grafana — metrics & logs for substreams-sec

Observability artifacts for the `db_out` → ClickHouse sink and the SEC tier1
Substreams endpoint. Import the dashboard, or use the queries below to fetch
metrics and logs directly via the Grafana HTTP API.

- **Ops Grafana:** https://ops.stats.pinax.network
- **Metrics:** VictoriaMetrics (Prometheus API), datasource `VictoriaMetrics-ops`
  (`uid=P87AA050F258FF1BD`)
- **Logs:** Quickwit. Substreams/sink logs are in `Quickwit_lxc`
  (`uid=PEBF3764A8DEEF7CB`); the k8s `Quickwit` (`uid=P0F86FA451D0A474A`) holds
  k8s workloads.

Auth: a Grafana service-account token in `$GRAFANA_TOKEN` (a `glsa_…` token).
All API calls below send `Authorization: Bearer $GRAFANA_TOKEN`.

## Files

| File | What |
|------|------|
| `substreams-sec.json` | Importable dashboard: sink throughput/errors/flush, tier1 head-drift & active requests, and Quickwit log panels. Datasources and `job`/`network` are template variables. |

## Import the dashboard

```bash
# via UI: Dashboards → New → Import → upload grafana/substreams-sec.json
# via API:
curl -s -H "Authorization: Bearer $GRAFANA_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"dashboard\": $(cat grafana/substreams-sec.json), \"overwrite\": true}" \
  https://ops.stats.pinax.network/api/dashboards/db
```

On import, pick the **Metrics source** and **Logs source** datasources, and set
**Tier1 network** (default `sec`) and **Sink job**.

## Sink metrics

`substreams-sink-sql` exposes Prometheus metrics on `--metrics-listen-addr`
(**default `localhost:9102`**). When running locally:

```bash
curl -s localhost:9102/metrics | grep '^substreams_sink'
```

| Metric | Type | Meaning |
|--------|------|---------|
| `substreams_sink_data_message` | counter | data messages received |
| `substreams_sink_message_size_bytes` | counter | total bytes received from the backend |
| `substreams_sink_data_message_size_bytes` | counter | total bytes of data messages |
| `substreams_sink_error` | counter | connection-loop restarts |
| `substreams_sink_backprocessing_completion` | gauge | `1` once the first live message arrives |
| `substreams_sink_undo_message` | counter | reorg/undo signals (SEC: none) |
| `substreams_sink_postgres_flushed_rows_count` | counter | rows written to ClickHouse |
| `substreams_sink_postgres_store_flush_count` | counter | flush operations |
| `substreams_sink_postgres_store_flush_duration` | counter | nanoseconds spent flushing |
| `substreams_sink_progress_message_last_block` | gauge | last processed range end (SEC `block_num = unix_seconds / 600`) |
| `substreams_sink_progress_message_total_processed_blocks` | gauge | total processed blocks |

Handy PromQL (all filter on `{job=~"$job"}`):

```promql
rate(substreams_sink_data_message[$__rate_interval])                                  # msgs/s
rate(substreams_sink_postgres_flushed_rows_count[$__rate_interval])                   # rows/s
rate(substreams_sink_error[$__rate_interval])                                         # errors/s
rate(substreams_sink_postgres_store_flush_duration[$__rate_interval])
  / clamp_min(rate(substreams_sink_postgres_store_flush_count[$__rate_interval]),1) / 1e6   # avg flush ms
```

> The **local** `make dev` sink is not scraped by ops VictoriaMetrics. Either
> point the dashboard's **Metrics source** at a local Prometheus scraping
> `localhost:9102`, or just read `:9102/metrics` directly.

## Tier1 server metrics

The Substreams tier1 servers report under `site` / `network` / `hostname`
labels (e.g. `head_block_time_drift`, `substreams_active_requests`,
`container_cpu_usage_seconds_total`).

```promql
head_block_time_drift{network=~"$network"}
substreams_active_requests{network=~"$network"}
```

> ⚠️ As of this writing the SEC endpoint
> (`sec-substreams-tier1-prod.kan-sst2.pinax.io`) is **not present** anywhere in
> ops monitoring. Checked:
> - **Substreams status** (`head_block_time_drift`, `substreams_active_requests`) — no `sec` network.
> - **Firehose drift** (`/d/drift-dashboard`, `head_block_time_drift` / `head_block_number`) — 50 networks, no `sec`.
> - There is no `sec`/`kan-sst2` `hostname` or `job` on any metric.
>
> These panels stay empty until the deployment is wired into monitoring. (Sites
> seen today: `foundry`, `kanata`, `lab`, `ottawa`, `river` — `kan-sst2` most
> likely maps to `kanata`.)

## Logs (Quickwit)

Logs live in Quickwit (`Quickwit_lxc`). Query syntax is Quickwit's. Patterns
used by the hosted dashboards:

| Source | Quickwit query |
|--------|----------------|
| Sink | `job:"substreams-sink-sql"` |
| Substreams tier1 | `template:"sf-el-ss-ss"` |

The Quickwit Grafana plugin is a *backend* datasource — its REST API is **not**
reachable through `/api/datasources/proxy`. Fetch logs through Grafana's
unified query endpoint `/api/ds/query`, sending the plugin's target shape
(`metrics` + `bucketAggs`):

```bash
QW=PEBF3764A8DEEF7CB   # Quickwit_lxc
curl -s -H "Authorization: Bearer $GRAFANA_TOKEN" -H 'Content-Type: application/json' \
  https://ops.stats.pinax.network/api/ds/query -d '{
    "from":"now-2h","to":"now",
    "queries":[{
      "refId":"A",
      "datasource":{"type":"quickwit-quickwit-datasource","uid":"'"$QW"'"},
      "query":"template:\"sf-el-ss-ss\"",
      "alias":"","timeField":"",
      "metrics":[{"id":"1","type":"logs"}],
      "bucketAggs":[{"field":"","id":"2","settings":{"interval":"auto"},"type":"date_histogram"}]
    }]
  }'
```

Results come back as Grafana data frames (`results.A.frames[].data.values`).

> Caveat: hosted sink/tier1 logs only appear once SEC ships logs to the cluster
> — as of this writing `template:"sf-el-ss-ss"` and `job:"substreams-sink-sql"`
> return **no** SEC rows. A **local** `make dev` run's logs are on your terminal
> (stderr), not in Quickwit.

## Current status / blockers

- **Recent data cannot be ingested yet.** Streaming a recent start block makes
  the engine backprocess from genesis, and the `db_out` wasm module crashes
  deterministically at **block 18227** with an allocation error
  (`handle_alloc_error` → `wasm unreachable`). ClickHouse currently only holds
  2003–2005 filings. This is a module bug to fix before backfilling.
- **SEC not in ops monitoring.** The tier1/sink panels populate only after the
  deployment is added to VictoriaMetrics/Quickwit (see caveats above).
