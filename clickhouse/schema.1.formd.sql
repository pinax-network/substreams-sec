-- Form D — notice of exempt offering (Reg D).

-- Header (issuer + offering economics).
CREATE TABLE IF NOT EXISTS formd_notices AS TEMPLATE_FILING;
ALTER TABLE formd_notices
    ADD COLUMN IF NOT EXISTS schema_version            String,
    ADD COLUMN IF NOT EXISTS submission_type           LowCardinality(String) COMMENT 'D | D/A',
    ADD COLUMN IF NOT EXISTS issuer_cik                String,
    ADD COLUMN IF NOT EXISTS entity_name               String,
    ADD COLUMN IF NOT EXISTS issuer_street1            String,
    ADD COLUMN IF NOT EXISTS issuer_street2            String,
    ADD COLUMN IF NOT EXISTS issuer_city               String,
    ADD COLUMN IF NOT EXISTS issuer_state              LowCardinality(String),
    ADD COLUMN IF NOT EXISTS issuer_zip_code           String,
    ADD COLUMN IF NOT EXISTS issuer_state_description  String,
    ADD COLUMN IF NOT EXISTS phone                     String,
    ADD COLUMN IF NOT EXISTS jurisdiction_of_inc       LowCardinality(String),
    ADD COLUMN IF NOT EXISTS entity_type               LowCardinality(String),
    ADD COLUMN IF NOT EXISTS year_of_inc               String,
    ADD COLUMN IF NOT EXISTS industry_group            LowCardinality(String),
    ADD COLUMN IF NOT EXISTS offering_is_amendment     Bool,
    ADD COLUMN IF NOT EXISTS date_of_first_sale        String,
    ADD COLUMN IF NOT EXISTS more_than_one_year        Bool,
    ADD COLUMN IF NOT EXISTS is_equity_type            Bool,
    ADD COLUMN IF NOT EXISTS federal_exemptions        String COMMENT 'comma-separated',
    ADD COLUMN IF NOT EXISTS minimum_investment        String,
    ADD COLUMN IF NOT EXISTS minimum_investment_num    Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_offering_amount     String,
    ADD COLUMN IF NOT EXISTS total_offering_amount_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_amount_sold         String,
    ADD COLUMN IF NOT EXISTS total_amount_sold_num     Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_remaining           String,
    ADD COLUMN IF NOT EXISTS total_remaining_num       Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS has_non_accredited_investors Bool,
    ADD COLUMN IF NOT EXISTS total_already_invested    String,
    ADD COLUMN IF NOT EXISTS total_already_invested_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS sales_commissions         String,
    ADD COLUMN IF NOT EXISTS sales_commissions_num     Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS finders_fees              String,
    ADD COLUMN IF NOT EXISTS finders_fees_num          Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS gross_proceeds_used       String,
    ADD COLUMN IF NOT EXISTS gross_proceeds_used_num   Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS related_person_count      UInt32,
    ADD PROJECTION IF NOT EXISTS prj_issuer_cik ( SELECT issuer_cik, count(), min(timestamp), max(timestamp) GROUP BY issuer_cik );

-- Related persons (executives, directors, promoters).
CREATE TABLE IF NOT EXISTS formd_related_persons AS TEMPLATE_FILING_CHILD;
ALTER TABLE formd_related_persons
    ADD COLUMN IF NOT EXISTS first_name                String,
    ADD COLUMN IF NOT EXISTS middle_name               String,
    ADD COLUMN IF NOT EXISTS last_name                 String,
    ADD COLUMN IF NOT EXISTS street1                   String,
    ADD COLUMN IF NOT EXISTS street2                   String,
    ADD COLUMN IF NOT EXISTS city                      String,
    ADD COLUMN IF NOT EXISTS state                     LowCardinality(String),
    ADD COLUMN IF NOT EXISTS zip_code                  String,
    ADD COLUMN IF NOT EXISTS state_description         String,
    ADD COLUMN IF NOT EXISTS relationships             String COMMENT 'comma-separated',
    ADD COLUMN IF NOT EXISTS relationship_clarification String;
