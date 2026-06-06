-- Form 144 — notice of proposed sale of restricted/control securities.

-- Header (one per filing).
CREATE TABLE IF NOT EXISTS form144_notices AS TEMPLATE_FILING;
ALTER TABLE form144_notices
    ADD COLUMN IF NOT EXISTS filer_cik                 String,
    ADD COLUMN IF NOT EXISTS issuer_cik                String,
    ADD COLUMN IF NOT EXISTS issuer_name               String,
    ADD COLUMN IF NOT EXISTS sec_file_number           String,
    ADD COLUMN IF NOT EXISTS issuer_street1            String,
    ADD COLUMN IF NOT EXISTS issuer_street2            String,
    ADD COLUMN IF NOT EXISTS issuer_city               String,
    ADD COLUMN IF NOT EXISTS issuer_state              LowCardinality(String),
    ADD COLUMN IF NOT EXISTS issuer_zip_code           String,
    ADD COLUMN IF NOT EXISTS issuer_state_description  String,
    ADD COLUMN IF NOT EXISTS issuer_contact_phone      String,
    ADD COLUMN IF NOT EXISTS person_for_whose_account  String,
    ADD COLUMN IF NOT EXISTS relationships_to_issuer   String COMMENT 'comma-separated',
    ADD COLUMN IF NOT EXISTS securities_class_title    String,
    ADD COLUMN IF NOT EXISTS broker_name               String,
    ADD COLUMN IF NOT EXISTS broker_street1            String,
    ADD COLUMN IF NOT EXISTS broker_street2            String,
    ADD COLUMN IF NOT EXISTS broker_city               String,
    ADD COLUMN IF NOT EXISTS broker_state              LowCardinality(String),
    ADD COLUMN IF NOT EXISTS broker_zip_code           String,
    ADD COLUMN IF NOT EXISTS broker_state_description  String,
    ADD COLUMN IF NOT EXISTS units_sold                String,
    ADD COLUMN IF NOT EXISTS units_sold_num            Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS aggregate_market_value    String,
    ADD COLUMN IF NOT EXISTS aggregate_market_value_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS units_outstanding         String,
    ADD COLUMN IF NOT EXISTS units_outstanding_num     Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS approx_sale_date          String,
    ADD COLUMN IF NOT EXISTS securities_exchange_name  String,
    ADD COLUMN IF NOT EXISTS nothing_sold_past_3_months Bool,
    ADD COLUMN IF NOT EXISTS remarks                   String,
    ADD COLUMN IF NOT EXISTS notice_date               String,
    ADD COLUMN IF NOT EXISTS signature                 String,
    ADD PROJECTION IF NOT EXISTS prj_issuer_cik ( SELECT issuer_cik, count(), min(timestamp), max(timestamp) GROUP BY issuer_cik );

-- Securities the filer proposes to sell.
CREATE TABLE IF NOT EXISTS form144_securities_to_be_sold AS TEMPLATE_FILING_CHILD;
ALTER TABLE form144_securities_to_be_sold
    ADD COLUMN IF NOT EXISTS securities_class_title    String,
    ADD COLUMN IF NOT EXISTS acquired_date             String,
    ADD COLUMN IF NOT EXISTS nature_of_acquisition     String,
    ADD COLUMN IF NOT EXISTS acquired_from             String,
    ADD COLUMN IF NOT EXISTS is_gift                   Bool,
    ADD COLUMN IF NOT EXISTS amount_acquired           String,
    ADD COLUMN IF NOT EXISTS amount_acquired_num       Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS payment_date              String,
    ADD COLUMN IF NOT EXISTS nature_of_payment         String;

-- Securities sold in the past 3 months.
CREATE TABLE IF NOT EXISTS form144_securities_sold_past_3_months AS TEMPLATE_FILING_CHILD;
ALTER TABLE form144_securities_sold_past_3_months
    ADD COLUMN IF NOT EXISTS seller_name               String,
    ADD COLUMN IF NOT EXISTS seller_street1            String,
    ADD COLUMN IF NOT EXISTS seller_street2            String,
    ADD COLUMN IF NOT EXISTS seller_city               String,
    ADD COLUMN IF NOT EXISTS seller_state              LowCardinality(String),
    ADD COLUMN IF NOT EXISTS seller_zip_code           String,
    ADD COLUMN IF NOT EXISTS seller_state_description  String,
    ADD COLUMN IF NOT EXISTS securities_class_title    String,
    ADD COLUMN IF NOT EXISTS sale_date                 String,
    ADD COLUMN IF NOT EXISTS amount_sold               String,
    ADD COLUMN IF NOT EXISTS amount_sold_num           Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS gross_proceeds            String,
    ADD COLUMN IF NOT EXISTS gross_proceeds_num        Float64 DEFAULT 0;
