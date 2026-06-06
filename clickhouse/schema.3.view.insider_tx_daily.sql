-- Read view over state_insider_tx_daily (SummingMergeTree) — final sums.
CREATE VIEW IF NOT EXISTS insider_tx_daily AS
SELECT
    issuer_cik,
    day,
    transaction_code,
    acquired_disposed_code,
    sum(txns)       AS txns,
    sum(shares)     AS shares,
    sum(notional)   AS notional
FROM state_insider_tx_daily
GROUP BY issuer_cik, day, transaction_code, acquired_disposed_code;
