//! SC 13D / 13G — >5% beneficial-ownership disclosure. Header + reporting persons.

use crate::pb::pinax::sec::v1::{BeneficialOwnershipReport, Filing};
use crate::{child_key, filing_key, join, set_address, set_amount, set_filing, set_filing_child};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::Tables;

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, report: &BeneficialOwnershipReport) {
    // -- header --
    let row = tables.create_row("beneficial_ownership_reports", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("subject_company_cik", &report.subject_company_cik);
    row.set("subject_company_name", &report.subject_company_name);
    row.set("cusip", &report.cusip);
    row.set("schedule_type", &report.schedule_type);
    row.set("filer_cik", &report.filer_cik);
    row.set("securities_class_title", &report.securities_class_title);
    row.set("event_date", &report.event_date);
    set_address(row, "issuer_", report.issuer_address.as_ref());
    row.set("rules_designated", join(&report.rules_designated));
    row.set("reporting_person_count", report.reporting_persons.len() as u32);

    // -- reporting persons --
    for (i, p) in report.reporting_persons.iter().enumerate() {
        let row = tables.create_row("beneficial_reporting_persons", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("person_cik", &p.cik);
        row.set("person_name", &p.name);
        row.set("fund_type", &p.fund_type);
        row.set("citizenship", &p.citizenship);
        set_amount(row, "sole_voting_power", "sole_voting_power_num", &p.sole_voting_power);
        set_amount(row, "shared_voting_power", "shared_voting_power_num", &p.shared_voting_power);
        set_amount(row, "sole_dispositive_power", "sole_dispositive_power_num", &p.sole_dispositive_power);
        set_amount(row, "shared_dispositive_power", "shared_dispositive_power_num", &p.shared_dispositive_power);
        set_amount(row, "aggregate_amount_owned", "aggregate_amount_owned_num", &p.aggregate_amount_owned);
        set_amount(row, "percent_of_class", "percent_of_class_num", &p.percent_of_class);
        row.set("type_of_reporting_person", &p.type_of_reporting_person);
    }
}
