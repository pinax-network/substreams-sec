-- Institutional manager registry (→ /v1/institutions). One row per 13F filing
-- manager CIK, with latest reported portfolio value and reporting period.
CREATE TABLE IF NOT EXISTS state_institutions (
    manager_cik     String,
    manager_name    AggregateFunction(argMax, String, DateTime),
    latest_period   SimpleAggregateFunction(max, String),
    latest_value    AggregateFunction(argMax, Float64, DateTime),
    reports         SimpleAggregateFunction(sum, UInt64),
    first_seen      SimpleAggregateFunction(min, DateTime),
    last_seen       SimpleAggregateFunction(max, DateTime)
)
ENGINE = AggregatingMergeTree
ORDER BY manager_cik;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_institutions TO state_institutions AS
SELECT
    filing_manager_cik AS manager_cik,
    argMaxState(filing_manager_name, timestamp)     AS manager_name,
    max(report_period)                              AS latest_period,
    argMaxState(table_value_total_num, timestamp)   AS latest_value,
    toUInt64(count())                               AS reports,
    min(timestamp)                                  AS first_seen,
    max(timestamp)                                  AS last_seen
FROM form13f_reports
WHERE filing_manager_cik != ''
GROUP BY filing_manager_cik;
