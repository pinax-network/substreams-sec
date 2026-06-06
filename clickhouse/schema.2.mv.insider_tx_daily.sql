-- Insider transaction rollup (→ /v1/transactions analytics). Per issuer, day,
-- transaction code (P/S/A/M/...), and acquired/disposed flag: count, total
-- shares, and notional (shares * price). SummingMergeTree auto-sums on merge.
CREATE TABLE IF NOT EXISTS state_insider_tx_daily (
    issuer_cik              String,
    day                     Date,
    transaction_code        LowCardinality(String),
    acquired_disposed_code  LowCardinality(String),
    txns                    UInt64,
    shares                  Float64,
    notional                Float64
)
ENGINE = SummingMergeTree
ORDER BY (issuer_cik, day, transaction_code, acquired_disposed_code);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_insider_tx_daily TO state_insider_tx_daily AS
SELECT
    cik AS issuer_cik,
    toDate(timestamp)                       AS day,
    transaction_code,
    acquired_disposed_code,
    toUInt64(count())                       AS txns,
    sum(shares_num)                         AS shares,
    sum(shares_num * price_per_share_num)   AS notional
FROM ownership_transactions
GROUP BY issuer_cik, day, transaction_code, acquired_disposed_code;
