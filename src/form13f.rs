//! Form 13F-HR / 13F-NT — institutional manager holdings. Cover + summary
//! header, other managers, and the info-table holdings.

use crate::pb::pinax::sec::v1::{Filing, Form13fReport};
use crate::{child_key, filing_key, join, set_address, set_amount, set_filing, set_filing_child};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::Tables;

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, report: &Form13fReport) {
    // -- header (cover + summary) --
    let row = tables.create_row("form13f_reports", filing_key(filing));
    set_filing(clock, filing, row);

    let cover = report.cover_page.clone().unwrap_or_default();
    row.set("report_type", &cover.report_type);
    row.set("form13f_file_number", &cover.form13f_file_number);
    row.set("report_period", &cover.period_of_report);
    let manager = cover.filing_manager.clone().unwrap_or_default();
    row.set("filing_manager_cik", &manager.cik);
    row.set("filing_manager_name", &manager.name);
    set_address(row, "filing_manager_", manager.address.as_ref());
    // (envelope `is_amendment` already set by set_filing)
    row.set("amendment_type", &cover.amendment_type);
    row.set("amendment_number", &cover.amendment_number);
    row.set("provide_info_for_instruction5", &cover.provide_info_for_instruction5);

    let summary = report.summary_page.clone().unwrap_or_default();
    row.set("other_included_managers_count", summary.other_included_managers_count);
    row.set("table_entry_total", summary.table_entry_total);
    set_amount(row, "table_value_total", "table_value_total_num", &summary.table_value_total);
    row.set("holding_count", report.holdings.len() as u32);

    // -- other managers --
    for (i, m) in summary.other_managers.iter().enumerate() {
        let row = tables.create_row("form13f_other_managers", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("manager_cik", &m.cik);
        row.set("manager_name", &m.name);
        row.set("form13f_file_number", &m.form13f_file_number);
    }

    // -- holdings (info table entries) --
    for (i, h) in report.holdings.iter().enumerate() {
        let row = tables.create_row("form13f_holdings", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("name_of_issuer", &h.name_of_issuer);
        row.set("title_of_class", &h.title_of_class);
        row.set("cusip", &h.cusip);
        row.set("figi", &h.figi);
        set_amount(row, "value", "value_num", &h.value);
        let shares = h.shares_or_principal.clone().unwrap_or_default();
        set_amount(row, "shares_or_principal_amount", "shares_or_principal_amount_num", &shares.amount);
        row.set("shares_or_principal_type", &shares.r#type);
        row.set("put_call", &h.put_call);
        row.set("investment_discretion", &h.investment_discretion);
        row.set("other_manager_ids", join(&h.other_manager_ids));
        let voting = h.voting_authority.clone().unwrap_or_default();
        set_amount(row, "voting_sole", "voting_sole_num", &voting.sole);
        set_amount(row, "voting_shared", "voting_shared_num", &voting.shared);
        set_amount(row, "voting_none", "voting_none_num", &voting.none);
    }
}
