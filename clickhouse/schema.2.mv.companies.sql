-- Company / filer registry (→ /v1/companies). One row per CIK seen as a filer,
-- with latest name, form types, filing count, and first/last activity.
CREATE TABLE IF NOT EXISTS state_companies (
    cik             String,
    company_name    AggregateFunction(argMax, String, DateTime),
    forms           AggregateFunction(groupUniqArray, String),
    filings         SimpleAggregateFunction(sum, UInt64),
    first_filing    SimpleAggregateFunction(min, DateTime),
    last_filing     SimpleAggregateFunction(max, DateTime)
)
ENGINE = AggregatingMergeTree
ORDER BY cik;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_companies TO state_companies AS
SELECT
    cik,
    argMaxState(company_name, timestamp) AS company_name,
    groupUniqArrayState(toString(form_type)) AS forms,
    toUInt64(count())                   AS filings,
    min(timestamp)                      AS first_filing,
    max(timestamp)                      AS last_filing
FROM filings
WHERE cik != ''
GROUP BY cik;
