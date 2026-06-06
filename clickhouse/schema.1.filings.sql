-- Master index: one row per filing in the stream (every form, parsed or not).
CREATE TABLE IF NOT EXISTS filings AS TEMPLATE_FILING;
ALTER TABLE filings
    ADD COLUMN IF NOT EXISTS body_kind   LowCardinality(String) COMMENT 'ownership|form13f|beneficial|form144|nport|form_d|npx|ncen|form_c|raw',
    ADD COLUMN IF NOT EXISTS has_raw_xml Bool,

    ADD PROJECTION IF NOT EXISTS prj_form_type ( SELECT form_type, count(), min(timestamp), max(timestamp) GROUP BY form_type ),
    ADD PROJECTION IF NOT EXISTS prj_cik ( SELECT cik, count(), min(timestamp), max(timestamp) GROUP BY cik ),
    -- point lookup by accession (master ORDER BY now leads with timestamp)
    ADD PROJECTION IF NOT EXISTS prj_accession ( SELECT * ORDER BY accession_number );

-- Filings that could not be parsed into a structured body (legacy HTML, etc.).
CREATE TABLE IF NOT EXISTS raw_filings AS TEMPLATE_FILING;
ALTER TABLE raw_filings
    ADD COLUMN IF NOT EXISTS reason LowCardinality(String) COMMENT 'legacy_html|unsupported_form|parse_error';
