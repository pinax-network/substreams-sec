-- Form N-PX — proxy-voting record.

-- Header (cover page).
CREATE TABLE IF NOT EXISTS npx_reports AS TEMPLATE_FILING;
ALTER TABLE npx_reports
    ADD COLUMN IF NOT EXISTS filer_cik                       String,
    ADD COLUMN IF NOT EXISTS year_or_quarter                 String,
    ADD COLUMN IF NOT EXISTS report_calendar_year            String,
    ADD COLUMN IF NOT EXISTS reporting_person_name           String,
    ADD COLUMN IF NOT EXISTS reporting_person_street1        String,
    ADD COLUMN IF NOT EXISTS reporting_person_street2        String,
    ADD COLUMN IF NOT EXISTS reporting_person_city           String,
    ADD COLUMN IF NOT EXISTS reporting_person_state          LowCardinality(String),
    ADD COLUMN IF NOT EXISTS reporting_person_zip_code       String,
    ADD COLUMN IF NOT EXISTS reporting_person_state_description String,
    ADD COLUMN IF NOT EXISTS report_type                     LowCardinality(String) COMMENT 'NOTICE | VOTING | COMBINATION',
    ADD COLUMN IF NOT EXISTS file_number                     String,
    ADD COLUMN IF NOT EXISTS reporting_crd_number            String,
    ADD COLUMN IF NOT EXISTS vote_count                       UInt32;

-- Votes (one per proposal voted).
CREATE TABLE IF NOT EXISTS npx_votes AS TEMPLATE_FILING_CHILD;
ALTER TABLE npx_votes
    ADD COLUMN IF NOT EXISTS issuer_name                     String,
    ADD COLUMN IF NOT EXISTS cusip                           String,
    ADD COLUMN IF NOT EXISTS isin                            String,
    ADD COLUMN IF NOT EXISTS figi                            String,
    ADD COLUMN IF NOT EXISTS meeting_date                    String,
    ADD COLUMN IF NOT EXISTS vote_description                String,
    ADD COLUMN IF NOT EXISTS vote_categories                 String COMMENT 'comma-separated',
    ADD COLUMN IF NOT EXISTS vote_source                     String,
    ADD COLUMN IF NOT EXISTS shares_voted                    String,
    ADD COLUMN IF NOT EXISTS shares_voted_num                Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS shares_on_loan                  String,
    ADD COLUMN IF NOT EXISTS shares_on_loan_num              Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS record_count                    UInt32,
    ADD PROJECTION IF NOT EXISTS prj_cusip ( SELECT cusip, count(), min(timestamp), max(timestamp) GROUP BY cusip );

-- Vote records (how each share block within a vote was cast).
-- child_index = vote_index * 100000 + record_index.
CREATE TABLE IF NOT EXISTS npx_vote_records AS TEMPLATE_FILING_CHILD;
ALTER TABLE npx_vote_records
    ADD COLUMN IF NOT EXISTS vote_index                      UInt32,
    ADD COLUMN IF NOT EXISTS record_index                    UInt32,
    ADD COLUMN IF NOT EXISTS cusip                           String,
    ADD COLUMN IF NOT EXISTS how_voted                       LowCardinality(String) COMMENT 'FOR/AGAINST/ABSTAIN/WITHHELD',
    ADD COLUMN IF NOT EXISTS shares_voted                    String,
    ADD COLUMN IF NOT EXISTS shares_voted_num                Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS management_recommendation       LowCardinality(String);
