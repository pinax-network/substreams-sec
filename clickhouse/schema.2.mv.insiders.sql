-- Insider / reporting-owner registry (→ /v1/registered-insiders). One row per
-- owner CIK across all Forms 3/4/5, with role flags ever asserted.
CREATE TABLE IF NOT EXISTS state_insiders (
    owner_cik       String,
    owner_name      AggregateFunction(argMax, String, DateTime),
    issuers         AggregateFunction(uniq, String),
    filings         SimpleAggregateFunction(sum, UInt64),
    ever_director   SimpleAggregateFunction(max, UInt8),
    ever_officer    SimpleAggregateFunction(max, UInt8),
    ever_ten_pct    SimpleAggregateFunction(max, UInt8),
    first_seen      SimpleAggregateFunction(min, DateTime),
    last_seen       SimpleAggregateFunction(max, DateTime)
)
ENGINE = AggregatingMergeTree
ORDER BY owner_cik;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_insiders TO state_insiders AS
SELECT
    owner_cik,
    argMaxState(owner_name, timestamp)   AS owner_name,
    uniqState(cik)                       AS issuers,
    toUInt64(count())                    AS filings,
    toUInt8(max(is_director))            AS ever_director,
    toUInt8(max(is_officer))             AS ever_officer,
    toUInt8(max(is_ten_percent_owner))   AS ever_ten_pct,
    min(timestamp)                       AS first_seen,
    max(timestamp)                       AS last_seen
FROM reporting_owners
WHERE owner_cik != ''
GROUP BY owner_cik;
