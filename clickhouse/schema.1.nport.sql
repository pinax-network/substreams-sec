-- Form N-PORT — monthly portfolio holdings of registered funds.

-- Header (one per filing).
CREATE TABLE IF NOT EXISTS nport_reports AS TEMPLATE_FILING;
ALTER TABLE nport_reports
    ADD COLUMN IF NOT EXISTS filer_cik             String,
    ADD COLUMN IF NOT EXISTS reg_name              String,
    ADD COLUMN IF NOT EXISTS reg_file_number       String,
    ADD COLUMN IF NOT EXISTS reg_cik               String,
    ADD COLUMN IF NOT EXISTS reg_lei               String,
    ADD COLUMN IF NOT EXISTS series_name           String,
    ADD COLUMN IF NOT EXISTS series_id             String,
    ADD COLUMN IF NOT EXISTS series_lei            String,
    ADD COLUMN IF NOT EXISTS rep_period_end        String,
    ADD COLUMN IF NOT EXISTS rep_period_date       String,
    ADD COLUMN IF NOT EXISTS is_final_filing       Bool,
    ADD COLUMN IF NOT EXISTS total_assets          String,
    ADD COLUMN IF NOT EXISTS total_assets_num      Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_liabilities     String,
    ADD COLUMN IF NOT EXISTS total_liabilities_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS net_assets            String,
    ADD COLUMN IF NOT EXISTS net_assets_num        Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS holding_count         UInt32,
    ADD PROJECTION IF NOT EXISTS prj_series_id ( SELECT series_id, count(), min(timestamp), max(timestamp) GROUP BY series_id );

-- Per-class monthly total returns (3 months).
CREATE TABLE IF NOT EXISTS nport_monthly_returns AS TEMPLATE_FILING_CHILD;
ALTER TABLE nport_monthly_returns
    ADD COLUMN IF NOT EXISTS class_id              String,
    ADD COLUMN IF NOT EXISTS return_month1         String,
    ADD COLUMN IF NOT EXISTS return_month1_num     Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS return_month2         String,
    ADD COLUMN IF NOT EXISTS return_month2_num     Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS return_month3         String,
    ADD COLUMN IF NOT EXISTS return_month3_num     Float64 DEFAULT 0;

-- Per-security holdings (with optional derivative + securities-lending blocks).
CREATE TABLE IF NOT EXISTS nport_holdings AS TEMPLATE_FILING_CHILD;
ALTER TABLE nport_holdings
    ADD COLUMN IF NOT EXISTS name                  String,
    ADD COLUMN IF NOT EXISTS lei                   String,
    ADD COLUMN IF NOT EXISTS title                 String,
    ADD COLUMN IF NOT EXISTS cusip                 String,
    ADD COLUMN IF NOT EXISTS isin                  String,
    ADD COLUMN IF NOT EXISTS ticker                String,
    ADD COLUMN IF NOT EXISTS other_identifier      String,
    ADD COLUMN IF NOT EXISTS balance               String,
    ADD COLUMN IF NOT EXISTS balance_num           Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS units                 LowCardinality(String),
    ADD COLUMN IF NOT EXISTS currency              LowCardinality(String),
    ADD COLUMN IF NOT EXISTS value_usd             String,
    ADD COLUMN IF NOT EXISTS value_usd_num         Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS pct_value             String,
    ADD COLUMN IF NOT EXISTS pct_value_num         Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS payoff_profile        LowCardinality(String),
    ADD COLUMN IF NOT EXISTS asset_category        LowCardinality(String),
    ADD COLUMN IF NOT EXISTS issuer_category       LowCardinality(String),
    ADD COLUMN IF NOT EXISTS investment_country    LowCardinality(String),
    ADD COLUMN IF NOT EXISTS fair_value_level      LowCardinality(String),
    ADD COLUMN IF NOT EXISTS is_restricted         Bool,
    -- derivative block (present for derivative positions) --
    ADD COLUMN IF NOT EXISTS deriv_category        LowCardinality(String) COMMENT 'OPT/FWD/FUT/SWP/SWO/OTH',
    ADD COLUMN IF NOT EXISTS deriv_counterparty_name String,
    ADD COLUMN IF NOT EXISTS deriv_counterparty_lei String,
    ADD COLUMN IF NOT EXISTS deriv_put_or_call     LowCardinality(String),
    ADD COLUMN IF NOT EXISTS deriv_written_or_purchased LowCardinality(String),
    ADD COLUMN IF NOT EXISTS deriv_ref_instrument_name String,
    ADD COLUMN IF NOT EXISTS deriv_ref_instrument_title String,
    ADD COLUMN IF NOT EXISTS deriv_ref_isin        String,
    ADD COLUMN IF NOT EXISTS deriv_ref_ticker      String,
    ADD COLUMN IF NOT EXISTS deriv_share_no        String,
    ADD COLUMN IF NOT EXISTS deriv_notional_amount String,
    ADD COLUMN IF NOT EXISTS deriv_notional_amount_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS deriv_exercise_price  String,
    ADD COLUMN IF NOT EXISTS deriv_exercise_price_num Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS deriv_exercise_currency LowCardinality(String),
    ADD COLUMN IF NOT EXISTS deriv_expiration_date String,
    ADD COLUMN IF NOT EXISTS deriv_delta           String,
    ADD COLUMN IF NOT EXISTS deriv_unrealized_appreciation String,
    ADD COLUMN IF NOT EXISTS deriv_unrealized_appreciation_num Float64 DEFAULT 0,
    -- securities-lending block --
    ADD COLUMN IF NOT EXISTS lending_is_cash_collateral Bool,
    ADD COLUMN IF NOT EXISTS lending_is_non_cash_collateral Bool,
    ADD COLUMN IF NOT EXISTS lending_is_loan_by_fund Bool,
    ADD COLUMN IF NOT EXISTS lending_loan_value    String,
    ADD COLUMN IF NOT EXISTS lending_loan_value_num Float64 DEFAULT 0,
    ADD PROJECTION IF NOT EXISTS prj_cusip ( SELECT cusip, count(), min(timestamp), max(timestamp) GROUP BY cusip );
