//! Master `filings` index (one row per filing) + `raw_filings` (unparsed forms).

use crate::pb::pinax::sec::v1::{Filing, RawFiling};
use crate::{filing_key, set_filing};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::Tables;

pub fn process_filing(tables: &mut Tables, clock: &Clock, filing: &Filing) {
    let row = tables.create_row("filings", filing_key(filing));
    set_filing(clock, filing, row);
    let body_kind = match &filing.body {
        Some(crate::pb::pinax::sec::v1::filing::Body::Ownership(_)) => "ownership",
        Some(crate::pb::pinax::sec::v1::filing::Body::Form13f(_)) => "form13f",
        Some(crate::pb::pinax::sec::v1::filing::Body::Beneficial(_)) => "beneficial",
        Some(crate::pb::pinax::sec::v1::filing::Body::Form144(_)) => "form144",
        Some(crate::pb::pinax::sec::v1::filing::Body::Nport(_)) => "nport",
        Some(crate::pb::pinax::sec::v1::filing::Body::FormD(_)) => "form_d",
        Some(crate::pb::pinax::sec::v1::filing::Body::Npx(_)) => "npx",
        Some(crate::pb::pinax::sec::v1::filing::Body::Ncen(_)) => "ncen",
        Some(crate::pb::pinax::sec::v1::filing::Body::FormC(_)) => "form_c",
        Some(crate::pb::pinax::sec::v1::filing::Body::Raw(_)) => "raw",
        None => "",
    };
    row.set("body_kind", body_kind);
    row.set("has_raw_xml", !filing.raw_xml.is_empty());
}

pub fn process_raw(tables: &mut Tables, clock: &Clock, filing: &Filing, raw: &RawFiling) {
    let row = tables.create_row("raw_filings", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("reason", &raw.reason);
}
