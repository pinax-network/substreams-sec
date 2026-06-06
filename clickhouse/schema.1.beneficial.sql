-- SC 13D / 13G — >5% beneficial-ownership disclosure.

-- Header (one per filing).
CREATE TABLE IF NOT EXISTS beneficial_ownership_reports AS TEMPLATE_FILING;
ALTER TABLE beneficial_ownership_reports
    ADD COLUMN IF NOT EXISTS subject_company_cik       String,
    ADD COLUMN IF NOT EXISTS subject_company_name      String,
    ADD COLUMN IF NOT EXISTS cusip                     String,
    ADD COLUMN IF NOT EXISTS schedule_type             LowCardinality(String) COMMENT 'SCHEDULE 13D|13G | SC 13D|13G',
    ADD COLUMN IF NOT EXISTS filer_cik                 String,
    ADD COLUMN IF NOT EXISTS securities_class_title    String,
    ADD COLUMN IF NOT EXISTS event_date                String,
    ADD COLUMN IF NOT EXISTS issuer_street1            String,
    ADD COLUMN IF NOT EXISTS issuer_street2            String,
    ADD COLUMN IF NOT EXISTS issuer_city               String,
    ADD COLUMN IF NOT EXISTS issuer_state              LowCardinality(String),
    ADD COLUMN IF NOT EXISTS issuer_zip_code           String,
    ADD COLUMN IF NOT EXISTS issuer_state_description  String,
    ADD COLUMN IF NOT EXISTS rules_designated          String COMMENT 'comma-separated rule cites',
    ADD COLUMN IF NOT EXISTS reporting_person_count    UInt32,
    ADD PROJECTION IF NOT EXISTS prj_cusip ( SELECT cusip, count(), min(timestamp), max(timestamp) GROUP BY cusip ),
    ADD PROJECTION IF NOT EXISTS prj_subject_cik ( SELECT subject_company_cik, count(), min(timestamp), max(timestamp) GROUP BY subject_company_cik );

-- Reporting persons + their voting/dispositive power.
CREATE TABLE IF NOT EXISTS beneficial_reporting_persons AS TEMPLATE_FILING_CHILD;
ALTER TABLE beneficial_reporting_persons
    ADD COLUMN IF NOT EXISTS person_cik                String,
    ADD COLUMN IF NOT EXISTS person_name               String,
    ADD COLUMN IF NOT EXISTS fund_type                 String,
    ADD COLUMN IF NOT EXISTS citizenship               String,
    ADD COLUMN IF NOT EXISTS sole_voting_power         String,
    ADD COLUMN IF NOT EXISTS sole_voting_power_num     Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS shared_voting_power       String,
    ADD COLUMN IF NOT EXISTS shared_voting_power_num   Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS sole_dispositive_power    String,
    ADD COLUMN IF NOT EXISTS sole_dispositive_power_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS shared_dispositive_power  String,
    ADD COLUMN IF NOT EXISTS shared_dispositive_power_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS aggregate_amount_owned    String,
    ADD COLUMN IF NOT EXISTS aggregate_amount_owned_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS percent_of_class          String,
    ADD COLUMN IF NOT EXISTS percent_of_class_num      Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS type_of_reporting_person  LowCardinality(String) COMMENT 'IN, HC, OO, ...';
