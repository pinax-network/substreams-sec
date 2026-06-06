-- Latest 13F position per (manager, security) (→ /v1/13f-holdings, the planned
-- `v_holdings_latest`). argMax over acceptance time keeps each manager's most
-- recent reported value/shares per CUSIP. `cik` on the holdings child is the
-- filing manager (filer) CIK.
CREATE TABLE IF NOT EXISTS state_holdings_13f_latest (
    manager_cik         String,
    cusip               String,
    issuer_name         AggregateFunction(argMax, String, DateTime),
    title_of_class      AggregateFunction(argMax, String, DateTime),
    value               AggregateFunction(argMax, Float64, DateTime),
    shares              AggregateFunction(argMax, Float64, DateTime),
    accession_number    AggregateFunction(argMax, String, DateTime),
    as_of               SimpleAggregateFunction(max, DateTime)
)
ENGINE = AggregatingMergeTree
ORDER BY (manager_cik, cusip);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_holdings_13f_latest TO state_holdings_13f_latest AS
SELECT
    cik AS manager_cik,
    cusip,
    argMaxState(name_of_issuer, timestamp)                   AS issuer_name,
    argMaxState(title_of_class, timestamp)                   AS title_of_class,
    argMaxState(value_num, timestamp)                        AS value,
    argMaxState(shares_or_principal_amount_num, timestamp)   AS shares,
    argMaxState(accession_number, timestamp)                 AS accession_number,
    max(timestamp)                                           AS as_of
FROM form13f_holdings
WHERE cusip != ''
GROUP BY manager_cik, cusip;
