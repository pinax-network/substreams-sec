//! Form N-PORT — monthly portfolio holdings of registered funds. Header +
//! per-class monthly returns + per-security holdings (with derivative & lending).

use crate::pb::pinax::sec::v1::{Filing, NportReport, PortfolioHolding};
use crate::{child_key, filing_key, set_amount, set_filing, set_filing_child};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::{Row, Tables};

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, report: &NportReport) {
    // -- header --
    let row = tables.create_row("nport_reports", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("filer_cik", &report.filer_cik);

    let gi = report.general_info.clone().unwrap_or_default();
    row.set("reg_name", &gi.reg_name);
    row.set("reg_file_number", &gi.reg_file_number);
    row.set("reg_cik", &gi.reg_cik);
    row.set("reg_lei", &gi.reg_lei);
    row.set("series_name", &gi.series_name);
    row.set("series_id", &gi.series_id);
    row.set("series_lei", &gi.series_lei);
    row.set("rep_period_end", &gi.rep_period_end);
    row.set("rep_period_date", &gi.rep_period_date);
    row.set("is_final_filing", gi.is_final_filing);

    let fund = report.fund_info.clone().unwrap_or_default();
    set_amount(row, "total_assets", "total_assets_num", &fund.total_assets);
    set_amount(row, "total_liabilities", "total_liabilities_num", &fund.total_liabilities);
    set_amount(row, "net_assets", "net_assets_num", &fund.net_assets);
    row.set("holding_count", report.holdings.len() as u32);

    // -- monthly returns (per share class) --
    for (i, r) in fund.monthly_total_returns.iter().enumerate() {
        let row = tables.create_row("nport_monthly_returns", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("class_id", &r.class_id);
        set_amount(row, "return_month1", "return_month1_num", &r.return_month1);
        set_amount(row, "return_month2", "return_month2_num", &r.return_month2);
        set_amount(row, "return_month3", "return_month3_num", &r.return_month3);
    }

    // -- holdings --
    for (i, h) in report.holdings.iter().enumerate() {
        process_holding(tables, clock, filing, i as u64, h);
    }
}

fn process_holding(tables: &mut Tables, clock: &Clock, filing: &Filing, i: u64, h: &PortfolioHolding) {
    let row = tables.create_row("nport_holdings", child_key(filing, i));
    set_filing_child(clock, filing, i, row);
    row.set("name", &h.name);
    row.set("lei", &h.lei);
    row.set("title", &h.title);
    row.set("cusip", &h.cusip);
    row.set("isin", &h.isin);
    row.set("ticker", &h.ticker);
    row.set("other_identifier", &h.other_identifier);
    set_amount(row, "balance", "balance_num", &h.balance);
    row.set("units", &h.units);
    row.set("currency", &h.currency);
    set_amount(row, "value_usd", "value_usd_num", &h.value_usd);
    set_amount(row, "pct_value", "pct_value_num", &h.pct_value);
    row.set("payoff_profile", &h.payoff_profile);
    row.set("asset_category", &h.asset_category);
    row.set("issuer_category", &h.issuer_category);
    row.set("investment_country", &h.investment_country);
    row.set("fair_value_level", &h.fair_value_level);
    row.set("is_restricted", h.is_restricted);
    set_derivative(row, h.derivative.as_ref());
    set_lending(row, h.security_lending.as_ref());
}

fn set_derivative(row: &mut Row, d: Option<&crate::pb::pinax::sec::v1::Derivative>) {
    let def = crate::pb::pinax::sec::v1::Derivative::default();
    let d = d.unwrap_or(&def);
    row.set("deriv_category", &d.category);
    row.set("deriv_counterparty_name", &d.counterparty_name);
    row.set("deriv_counterparty_lei", &d.counterparty_lei);
    row.set("deriv_put_or_call", &d.put_or_call);
    row.set("deriv_written_or_purchased", &d.written_or_purchased);
    row.set("deriv_ref_instrument_name", &d.ref_instrument_name);
    row.set("deriv_ref_instrument_title", &d.ref_instrument_title);
    row.set("deriv_ref_isin", &d.ref_isin);
    row.set("deriv_ref_ticker", &d.ref_ticker);
    row.set("deriv_share_no", &d.share_no);
    set_amount(row, "deriv_notional_amount", "deriv_notional_amount_num", &d.notional_amount);
    set_amount(row, "deriv_exercise_price", "deriv_exercise_price_num", &d.exercise_price);
    row.set("deriv_exercise_currency", &d.exercise_currency);
    row.set("deriv_expiration_date", &d.expiration_date);
    row.set("deriv_delta", &d.delta);
    set_amount(row, "deriv_unrealized_appreciation", "deriv_unrealized_appreciation_num", &d.unrealized_appreciation);
}

fn set_lending(row: &mut Row, l: Option<&crate::pb::pinax::sec::v1::SecurityLending>) {
    let def = crate::pb::pinax::sec::v1::SecurityLending::default();
    let l = l.unwrap_or(&def);
    row.set("lending_is_cash_collateral", l.is_cash_collateral);
    row.set("lending_is_non_cash_collateral", l.is_non_cash_collateral);
    row.set("lending_is_loan_by_fund", l.is_loan_by_fund);
    set_amount(row, "lending_loan_value", "lending_loan_value_num", &l.loan_value);
}
