//! Form N-PX — proxy-voting record. Header + per-proposal votes + per-vote
//! records (how each share block was voted).

use crate::pb::pinax::sec::v1::{Filing, NpxReport};
use crate::{child_key, filing_key, join, set_address, set_amount, set_filing, set_filing_child};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::Tables;

// Spread for the composite vote-record index (record_index within a vote).
const RECORDS_PER_VOTE: u64 = 100_000;

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, report: &NpxReport) {
    // -- header --
    let row = tables.create_row("npx_reports", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("filer_cik", &report.filer_cik);
    let cover = report.cover_page.clone().unwrap_or_default();
    row.set("year_or_quarter", &cover.year_or_quarter);
    row.set("report_calendar_year", &cover.report_calendar_year);
    row.set("reporting_person_name", &cover.reporting_person_name);
    set_address(row, "reporting_person_", cover.reporting_person_address.as_ref());
    row.set("report_type", &cover.report_type);
    row.set("file_number", &cover.file_number);
    row.set("reporting_crd_number", &cover.reporting_crd_number);
    row.set("vote_count", report.votes.len() as u32);

    // -- votes + vote records --
    for (vi, vote) in report.votes.iter().enumerate() {
        let vote_index = vi as u64;
        let row = tables.create_row("npx_votes", child_key(filing, vote_index));
        set_filing_child(clock, filing, vote_index, row);
        row.set("issuer_name", &vote.issuer_name);
        row.set("cusip", &vote.cusip);
        row.set("isin", &vote.isin);
        row.set("figi", &vote.figi);
        row.set("meeting_date", &vote.meeting_date);
        row.set("vote_description", &vote.vote_description);
        row.set("vote_categories", join(&vote.vote_categories));
        row.set("vote_source", &vote.vote_source);
        set_amount(row, "shares_voted", "shares_voted_num", &vote.shares_voted);
        set_amount(row, "shares_on_loan", "shares_on_loan_num", &vote.shares_on_loan);
        row.set("record_count", vote.records.len() as u32);

        for (ri, rec) in vote.records.iter().enumerate() {
            let child_index = vote_index * RECORDS_PER_VOTE + ri as u64;
            let row = tables.create_row("npx_vote_records", child_key(filing, child_index));
            set_filing_child(clock, filing, child_index, row);
            row.set("vote_index", vote_index as u32);
            row.set("record_index", ri as u32);
            row.set("cusip", &vote.cusip);
            row.set("how_voted", &rec.how_voted);
            set_amount(row, "shares_voted", "shares_voted_num", &rec.shares_voted);
            row.set("management_recommendation", &rec.management_recommendation);
        }
    }
}
