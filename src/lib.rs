//! SEC EDGAR Substreams — `db_out` map producing ClickHouse `DatabaseChanges`.
//!
//! Consumes the Firehose `pinax.sec.v1.Block` (one EDGAR filing day;
//! `block_number` = days since the Unix epoch) and
//! flattens every `Filing` into relational rows. Each filing always yields one
//! row in the master `filings` index; structured bodies (Forms 3/4/5, 13F, SC
//! 13D/G, 144, N-PORT, Form D, N-PX, N-CEN, Form C) additionally fan out into
//! per-form header + child tables, all keyed by `accession_number`.

mod beneficial;
mod filings;
mod form13f;
mod form144;
mod formc;
mod formd;
mod ncen;
mod nport;
mod npx;
mod ownership;
pub mod pb;

use crate::pb::pinax::sec::v1::{filing::Body, Address, Block, Filing};
use substreams::errors::Error;
use substreams::pb::substreams::Clock;
use substreams_database_change::pb::database::DatabaseChanges;
use substreams_database_change::tables::{Row, Tables};

#[substreams::handlers::map]
pub fn db_out(clock: Clock, block: Block) -> Result<DatabaseChanges, Error> {
    let mut tables = Tables::new();

    for filing in &block.filings {
        // Master index — one row per filing, regardless of body type.
        filings::process_filing(&mut tables, &clock, filing);

        // Structured body fan-out.
        match &filing.body {
            Some(Body::Ownership(doc)) => ownership::process(&mut tables, &clock, filing, doc),
            Some(Body::Form13f(report)) => form13f::process(&mut tables, &clock, filing, report),
            Some(Body::Beneficial(report)) => beneficial::process(&mut tables, &clock, filing, report),
            Some(Body::Form144(notice)) => form144::process(&mut tables, &clock, filing, notice),
            Some(Body::Nport(report)) => nport::process(&mut tables, &clock, filing, report),
            Some(Body::FormD(notice)) => formd::process(&mut tables, &clock, filing, notice),
            Some(Body::Npx(report)) => npx::process(&mut tables, &clock, filing, report),
            Some(Body::Ncen(report)) => ncen::process(&mut tables, &clock, filing, report),
            Some(Body::FormC(notice)) => formc::process(&mut tables, &clock, filing, notice),
            Some(Body::Raw(raw)) => filings::process_raw(&mut tables, &clock, filing, raw),
            None => {}
        }
    }

    // Only emit a block row when the window carried filings (empty EDGAR
    // windows are still streamed for contiguity, but need no row).
    if !tables.tables.is_empty() {
        let row = tables.create_row("blocks", [("block_num", clock.number.to_string())]);
        set_block(&clock, &block, row);
    }

    substreams::log::info!("SEC filings: {}, rows: {}", block.filings.len(), tables.all_row_count());
    Ok(tables.to_database_changes())
}

// -- helpers ---------------------------------------------------------------

/// Seconds since epoch from an optional protobuf Timestamp (0 when absent).
pub fn ts_seconds(t: Option<&prost_types::Timestamp>) -> i64 {
    t.map(|t| t.seconds).unwrap_or(0)
}

/// Parse a raw decimal string to f64, defaulting to 0.0 on failure.
pub fn parse_f64(value: &str) -> f64 {
    value.parse().unwrap_or(0.0)
}

/// Set a paired `<field>` (raw string) + `<field>_num` (Float64) for a numeric
/// value reported as a raw XML string.
pub fn set_amount(row: &mut Row, field: &str, num_field: &str, value: &str) {
    row.set(field, value);
    row.set(num_field, parse_f64(value).to_string());
}

/// Join a repeated string field into a single comma-separated column. EDGAR
/// uses these for short enumerations (relationships, exemptions, rule cites);
/// query with `has(splitByChar(',', col), 'X')`.
pub fn join(values: &[String]) -> String {
    values.join(",")
}

/// Flatten an (optional) `Address` into `<prefix>street1 .. <prefix>state_description`.
pub fn set_address(row: &mut Row, prefix: &str, addr: Option<&Address>) {
    let default = Address::default();
    let a = addr.unwrap_or(&default);
    row.set(format!("{prefix}street1").as_str(), &a.street1);
    row.set(format!("{prefix}street2").as_str(), &a.street2);
    row.set(format!("{prefix}city").as_str(), &a.city);
    row.set(format!("{prefix}state").as_str(), &a.state);
    row.set(format!("{prefix}zip_code").as_str(), &a.zip_code);
    row.set(format!("{prefix}state_description").as_str(), &a.state_description);
}

/// Block metadata for the `blocks` table.
pub fn set_block(clock: &Clock, block: &Block, row: &mut Row) {
    row.set("block_num", clock.number);
    row.set("block_hash", format!("0x{}", clock.id));
    row.set("timestamp", clock.timestamp.as_ref().map(|t| t.seconds).unwrap_or(0));
    let feed_date = block.header.as_ref().map(|h| h.feed_date.as_str()).unwrap_or("");
    row.set("feed_date", feed_date);
}

/// Natural primary key for a one-per-filing table.
pub fn filing_key(filing: &Filing) -> [(&'static str, String); 1] {
    [("accession_number", filing.accession_number.clone())]
}

/// Primary key for a child table (`accession_number` + position within filing).
pub fn child_key(filing: &Filing, child_index: u64) -> [(&'static str, String); 2] {
    [
        ("accession_number", filing.accession_number.clone()),
        ("child_index", child_index.to_string()),
    ]
}

/// Full filing envelope — used by `filings` and every per-form header table
/// (TEMPLATE_FILING columns).
pub fn set_filing(clock: &Clock, filing: &Filing, row: &mut Row) {
    row.set("block_num", clock.number);
    row.set("block_hash", format!("0x{}", clock.id));
    row.set("timestamp", clock.timestamp.as_ref().map(|t| t.seconds).unwrap_or(0));
    row.set("filing_index", filing.ordinal as u32);
    row.set("accession_number", &filing.accession_number);
    row.set("form_type", &filing.form_type);
    row.set("cik", &filing.cik);
    row.set("company_name", &filing.company_name);
    row.set("filing_date", &filing.filing_date);
    row.set("period_of_report", &filing.period_of_report);
    row.set("acceptance_datetime", ts_seconds(filing.acceptance_datetime.as_ref()));
    row.set("primary_document", &filing.primary_document);
    row.set("is_amendment", filing.is_amendment);
    row.set("amended_accession", &filing.amended_accession);
    row.set("source_path", &filing.source_path);
}

/// Lean filing envelope for child tables (TEMPLATE_FILING_CHILD columns):
/// enough to time-filter and join back to `filings` without the wide envelope.
pub fn set_filing_child(clock: &Clock, filing: &Filing, child_index: u64, row: &mut Row) {
    row.set("block_num", clock.number);
    row.set("block_hash", format!("0x{}", clock.id));
    row.set("timestamp", clock.timestamp.as_ref().map(|t| t.seconds).unwrap_or(0));
    row.set("accession_number", &filing.accession_number);
    row.set("form_type", &filing.form_type);
    row.set("cik", &filing.cik);
    row.set("child_index", child_index as u32);
}
