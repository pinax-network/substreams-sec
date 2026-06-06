-- Form N-CEN — registered-fund annual census (v1: registrant header + series).
CREATE TABLE IF NOT EXISTS ncen_reports AS TEMPLATE_FILING;
ALTER TABLE ncen_reports
    ADD COLUMN IF NOT EXISTS filer_cik                  String,
    ADD COLUMN IF NOT EXISTS investment_company_type    LowCardinality(String) COMMENT 'e.g. N-1A',
    ADD COLUMN IF NOT EXISTS report_ending_period       String,
    ADD COLUMN IF NOT EXISTS is_report_period_lt12      Bool,
    ADD COLUMN IF NOT EXISTS registrant_full_name       String,
    ADD COLUMN IF NOT EXISTS registrant_file_number     String,
    ADD COLUMN IF NOT EXISTS registrant_cik             String,
    ADD COLUMN IF NOT EXISTS registrant_lei             String,
    ADD COLUMN IF NOT EXISTS registrant_street1         String,
    ADD COLUMN IF NOT EXISTS registrant_street2         String,
    ADD COLUMN IF NOT EXISTS registrant_city            String,
    ADD COLUMN IF NOT EXISTS registrant_state           LowCardinality(String),
    ADD COLUMN IF NOT EXISTS registrant_zip_code        String,
    ADD COLUMN IF NOT EXISTS registrant_state_description String,
    ADD COLUMN IF NOT EXISTS registrant_phone           String,
    ADD COLUMN IF NOT EXISTS series_ids                 String COMMENT 'comma-separated series ids',
    ADD COLUMN IF NOT EXISTS series_count               UInt32,
    ADD PROJECTION IF NOT EXISTS prj_registrant_cik ( SELECT registrant_cik, count(), min(timestamp), max(timestamp) GROUP BY registrant_cik );
