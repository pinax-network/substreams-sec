-- Templates for SEC filings.
-- EDGAR has no chain — filings are bucketed into 10-minute windows by their
-- acceptance time. Every table denormalizes the window + filing envelope so it
-- can be time-filtered and joined back to `filings` on `accession_number`.

-- TEMPLATE_FILING — one row per filing. Used by `filings` and every per-form
-- header table. Keyed by the globally-unique EDGAR accession number.
CREATE TABLE IF NOT EXISTS TEMPLATE_FILING (
    -- window --
    block_num                   UInt64,
    block_hash                  String,
    timestamp                   DateTime('UTC') COMMENT 'window start (acceptance bucket)',
    minute                      UInt32 MATERIALIZED toRelativeMinuteNum(timestamp),

    -- filing envelope --
    filing_index                UInt32 COMMENT 'ordinal within the window',
    accession_number            String,
    form_type                   LowCardinality(String),
    cik                         String COMMENT 'filer CIK (10-pad)',
    company_name                String,
    filing_date                 String COMMENT 'YYYY-MM-DD (raw)',
    period_of_report            String,
    acceptance_datetime         DateTime('UTC'),
    primary_document            String,
    is_amendment                Bool,
    amended_accession           String,
    source_path                 String
)
ENGINE = ReplacingMergeTree
-- timestamp first: raw events are time-series — (timestamp, accession) is still a
-- unique dedup key since a filing's window is fixed by its accession.
ORDER BY ( timestamp, accession_number )
SETTINGS deduplicate_merge_projection_mode = 'rebuild';

-- TEMPLATE_FILING_CHILD — repeated sub-records of a filing (transactions,
-- holdings, persons, votes, ...). Lean envelope + position within the filing.
CREATE TABLE IF NOT EXISTS TEMPLATE_FILING_CHILD (
    block_num                   UInt64,
    block_hash                  String,
    timestamp                   DateTime('UTC'),
    minute                      UInt32 MATERIALIZED toRelativeMinuteNum(timestamp),
    accession_number            String,
    form_type                   LowCardinality(String),
    cik                         String,
    child_index                 UInt32 COMMENT 'position within the filing'
)
ENGINE = ReplacingMergeTree
-- timestamp first (time-series) — (timestamp, accession, child_index) stays unique.
ORDER BY ( timestamp, accession_number, child_index )
SETTINGS deduplicate_merge_projection_mode = 'rebuild';
