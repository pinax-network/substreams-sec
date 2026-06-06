-- Form 13F-HR / 13F-NT — institutional manager holdings.

-- Header (cover page + summary).
CREATE TABLE IF NOT EXISTS form13f_reports AS TEMPLATE_FILING;
ALTER TABLE form13f_reports
    ADD COLUMN IF NOT EXISTS report_type                   LowCardinality(String),
    ADD COLUMN IF NOT EXISTS form13f_file_number           String,
    ADD COLUMN IF NOT EXISTS report_period                 String COMMENT 'cover periodOfReport',
    ADD COLUMN IF NOT EXISTS filing_manager_cik            String,
    ADD COLUMN IF NOT EXISTS filing_manager_name           String,
    ADD COLUMN IF NOT EXISTS filing_manager_street1        String,
    ADD COLUMN IF NOT EXISTS filing_manager_street2        String,
    ADD COLUMN IF NOT EXISTS filing_manager_city           String,
    ADD COLUMN IF NOT EXISTS filing_manager_state          LowCardinality(String),
    ADD COLUMN IF NOT EXISTS filing_manager_zip_code       String,
    ADD COLUMN IF NOT EXISTS filing_manager_state_description String,
    ADD COLUMN IF NOT EXISTS amendment_type                LowCardinality(String),
    ADD COLUMN IF NOT EXISTS amendment_number              String,
    ADD COLUMN IF NOT EXISTS provide_info_for_instruction5 String,
    ADD COLUMN IF NOT EXISTS other_included_managers_count UInt32,
    ADD COLUMN IF NOT EXISTS table_entry_total             UInt32,
    ADD COLUMN IF NOT EXISTS table_value_total             String,
    ADD COLUMN IF NOT EXISTS table_value_total_num         Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS holding_count                 UInt32,
    ADD PROJECTION IF NOT EXISTS prj_manager_cik ( SELECT filing_manager_cik, count(), min(timestamp), max(timestamp) GROUP BY filing_manager_cik );

-- Other included managers (cover summary).
CREATE TABLE IF NOT EXISTS form13f_other_managers AS TEMPLATE_FILING_CHILD;
ALTER TABLE form13f_other_managers
    ADD COLUMN IF NOT EXISTS manager_cik                   String,
    ADD COLUMN IF NOT EXISTS manager_name                  String,
    ADD COLUMN IF NOT EXISTS form13f_file_number           String;

-- Info-table holdings (one row per reported position).
CREATE TABLE IF NOT EXISTS form13f_holdings AS TEMPLATE_FILING_CHILD;
ALTER TABLE form13f_holdings
    ADD COLUMN IF NOT EXISTS name_of_issuer                String,
    ADD COLUMN IF NOT EXISTS title_of_class                String,
    ADD COLUMN IF NOT EXISTS cusip                         String,
    ADD COLUMN IF NOT EXISTS figi                          String,
    ADD COLUMN IF NOT EXISTS value                         String COMMENT 'RAW (not x1000)',
    ADD COLUMN IF NOT EXISTS value_num                     Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS shares_or_principal_amount    String,
    ADD COLUMN IF NOT EXISTS shares_or_principal_amount_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS shares_or_principal_type      LowCardinality(String) COMMENT 'SH | PRN',
    ADD COLUMN IF NOT EXISTS put_call                      LowCardinality(String) COMMENT 'PUT | CALL | ""',
    ADD COLUMN IF NOT EXISTS investment_discretion         LowCardinality(String),
    ADD COLUMN IF NOT EXISTS other_manager_ids             String,
    ADD COLUMN IF NOT EXISTS voting_sole                   String,
    ADD COLUMN IF NOT EXISTS voting_sole_num               Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS voting_shared                 String,
    ADD COLUMN IF NOT EXISTS voting_shared_num             Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS voting_none                   String,
    ADD COLUMN IF NOT EXISTS voting_none_num               Float64 DEFAULT 0,
    ADD PROJECTION IF NOT EXISTS prj_cusip ( SELECT cusip, count(), min(timestamp), max(timestamp) GROUP BY cusip );
