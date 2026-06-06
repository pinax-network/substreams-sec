//! Form N-CEN — registered-fund annual census (v1: registrant header + series).

use crate::pb::pinax::sec::v1::{Filing, NcenReport};
use crate::{filing_key, join, set_address, set_filing};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::Tables;

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, report: &NcenReport) {
    let row = tables.create_row("ncen_reports", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("filer_cik", &report.filer_cik);
    row.set("investment_company_type", &report.investment_company_type);
    row.set("report_ending_period", &report.report_ending_period);
    row.set("is_report_period_lt12", report.is_report_period_lt12);

    let reg = report.registrant.clone().unwrap_or_default();
    row.set("registrant_full_name", &reg.full_name);
    row.set("registrant_file_number", &reg.file_number);
    row.set("registrant_cik", &reg.cik);
    row.set("registrant_lei", &reg.lei);
    set_address(row, "registrant_", reg.address.as_ref());
    row.set("registrant_phone", &reg.phone);
    row.set("series_ids", join(&report.series_ids));
    row.set("series_count", report.series_ids.len() as u32);
}
