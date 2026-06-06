-- Forms 3/4/5 — Section 16 insider ownership.

-- Header (one per filing).
CREATE TABLE IF NOT EXISTS ownership_documents AS TEMPLATE_FILING;
ALTER TABLE ownership_documents
    ADD COLUMN IF NOT EXISTS schema_version            String,
    ADD COLUMN IF NOT EXISTS document_type             LowCardinality(String) COMMENT '3 | 4 | 5',
    ADD COLUMN IF NOT EXISTS document_period_of_report String,
    ADD COLUMN IF NOT EXISTS not_subject_to_section16  Bool,
    ADD COLUMN IF NOT EXISTS remarks                   String,
    ADD COLUMN IF NOT EXISTS issuer_cik                String,
    ADD COLUMN IF NOT EXISTS issuer_name               String,
    ADD COLUMN IF NOT EXISTS issuer_trading_symbol     LowCardinality(String),
    ADD COLUMN IF NOT EXISTS reporting_owner_count     UInt32,
    ADD PROJECTION IF NOT EXISTS prj_issuer_cik ( SELECT issuer_cik, count(), min(timestamp), max(timestamp) GROUP BY issuer_cik );

-- Reporting owners (insiders) for each filing.
CREATE TABLE IF NOT EXISTS reporting_owners AS TEMPLATE_FILING_CHILD;
ALTER TABLE reporting_owners
    ADD COLUMN IF NOT EXISTS owner_cik                 String,
    ADD COLUMN IF NOT EXISTS owner_name                String,
    ADD COLUMN IF NOT EXISTS owner_street1             String,
    ADD COLUMN IF NOT EXISTS owner_street2             String,
    ADD COLUMN IF NOT EXISTS owner_city                String,
    ADD COLUMN IF NOT EXISTS owner_state               LowCardinality(String),
    ADD COLUMN IF NOT EXISTS owner_zip_code            String,
    ADD COLUMN IF NOT EXISTS owner_state_description   String,
    ADD COLUMN IF NOT EXISTS is_director               Bool,
    ADD COLUMN IF NOT EXISTS is_officer                Bool,
    ADD COLUMN IF NOT EXISTS is_ten_percent_owner      Bool,
    ADD COLUMN IF NOT EXISTS is_other                  Bool,
    ADD COLUMN IF NOT EXISTS officer_title             String,
    ADD COLUMN IF NOT EXISTS other_text                String,
    ADD PROJECTION IF NOT EXISTS prj_owner_cik ( SELECT owner_cik, count(), min(timestamp), max(timestamp) GROUP BY owner_cik );

-- Non-derivative + derivative transactions (the insider trades).
CREATE TABLE IF NOT EXISTS ownership_transactions AS TEMPLATE_FILING_CHILD;
ALTER TABLE ownership_transactions
    ADD COLUMN IF NOT EXISTS table_type                LowCardinality(String) COMMENT 'non_derivative | derivative',
    ADD COLUMN IF NOT EXISTS security_title            String,
    ADD COLUMN IF NOT EXISTS transaction_date          String,
    ADD COLUMN IF NOT EXISTS deemed_execution_date     String,
    ADD COLUMN IF NOT EXISTS transaction_form_type     LowCardinality(String),
    ADD COLUMN IF NOT EXISTS transaction_code          LowCardinality(String) COMMENT 'P,S,A,M,G,F,D,...',
    ADD COLUMN IF NOT EXISTS equity_swap_involved      Bool,
    ADD COLUMN IF NOT EXISTS transaction_timeliness    String,
    ADD COLUMN IF NOT EXISTS shares                    String,
    ADD COLUMN IF NOT EXISTS shares_num                Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS price_per_share           String,
    ADD COLUMN IF NOT EXISTS price_per_share_num       Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS acquired_disposed_code    LowCardinality(String) COMMENT 'A | D',
    ADD COLUMN IF NOT EXISTS shares_owned_following    String,
    ADD COLUMN IF NOT EXISTS shares_owned_following_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS value_owned_following     String,
    ADD COLUMN IF NOT EXISTS value_owned_following_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS direct_or_indirect        LowCardinality(String) COMMENT 'D | I',
    ADD COLUMN IF NOT EXISTS nature_of_ownership       String,
    ADD COLUMN IF NOT EXISTS conversion_or_exercise_price String,
    ADD COLUMN IF NOT EXISTS exercise_date             String,
    ADD COLUMN IF NOT EXISTS expiration_date           String,
    ADD COLUMN IF NOT EXISTS underlying_title          String,
    ADD COLUMN IF NOT EXISTS underlying_shares         String,
    ADD COLUMN IF NOT EXISTS underlying_value          String,
    ADD COLUMN IF NOT EXISTS footnote_ids              String COMMENT 'comma-separated footnote ids',
    ADD PROJECTION IF NOT EXISTS prj_code ( SELECT transaction_code, count(), min(timestamp), max(timestamp) GROUP BY transaction_code );

-- Non-derivative + derivative holdings.
CREATE TABLE IF NOT EXISTS ownership_holdings AS TEMPLATE_FILING_CHILD;
ALTER TABLE ownership_holdings
    ADD COLUMN IF NOT EXISTS table_type                LowCardinality(String) COMMENT 'non_derivative | derivative',
    ADD COLUMN IF NOT EXISTS security_title            String,
    ADD COLUMN IF NOT EXISTS shares_owned              String,
    ADD COLUMN IF NOT EXISTS shares_owned_num          Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS direct_or_indirect        LowCardinality(String),
    ADD COLUMN IF NOT EXISTS nature_of_ownership       String,
    ADD COLUMN IF NOT EXISTS conversion_or_exercise_price String,
    ADD COLUMN IF NOT EXISTS exercise_date             String,
    ADD COLUMN IF NOT EXISTS expiration_date           String,
    ADD COLUMN IF NOT EXISTS underlying_title          String,
    ADD COLUMN IF NOT EXISTS underlying_shares         String,
    ADD COLUMN IF NOT EXISTS underlying_value          String,
    ADD COLUMN IF NOT EXISTS footnote_ids              String;

-- Footnotes referenced by transactions/holdings.
CREATE TABLE IF NOT EXISTS ownership_footnotes AS TEMPLATE_FILING_CHILD;
ALTER TABLE ownership_footnotes
    ADD COLUMN IF NOT EXISTS footnote_id               String,
    ADD COLUMN IF NOT EXISTS text                      String;

-- Owner signatures.
CREATE TABLE IF NOT EXISTS ownership_signatures AS TEMPLATE_FILING_CHILD;
ALTER TABLE ownership_signatures
    ADD COLUMN IF NOT EXISTS signature_name            String,
    ADD COLUMN IF NOT EXISTS signature_date            String;
