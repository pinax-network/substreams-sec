//! Forms 3/4/5 — Section 16 insider ownership. Header + reporting owners +
//! non-derivative/derivative transactions & holdings + footnotes + signatures.

use crate::pb::pinax::sec::v1::{Holding, OwnershipDocument, ReportingOwner, Transaction};
use crate::{child_key, filing_key, join, set_address, set_amount, set_filing, set_filing_child};
use crate::pb::pinax::sec::v1::Filing;
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::{Row, Tables};

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, doc: &OwnershipDocument) {
    // -- header --
    let row = tables.create_row("ownership_documents", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("schema_version", &doc.schema_version);
    row.set("document_type", &doc.document_type);
    row.set("document_period_of_report", &doc.period_of_report);
    row.set("not_subject_to_section16", doc.not_subject_to_section16);
    row.set("remarks", &doc.remarks);
    let issuer = doc.issuer.clone().unwrap_or_default();
    row.set("issuer_cik", &issuer.cik);
    row.set("issuer_name", &issuer.name);
    row.set("issuer_trading_symbol", &issuer.trading_symbol);
    row.set("reporting_owner_count", doc.reporting_owners.len() as u32);

    // -- reporting owners --
    for (i, owner) in doc.reporting_owners.iter().enumerate() {
        process_owner(tables, clock, filing, i as u64, owner);
    }

    // -- transactions (non-derivative then derivative) --
    let mut idx = 0u64;
    for tx in &doc.non_derivative_transactions {
        process_transaction(tables, clock, filing, idx, "non_derivative", tx);
        idx += 1;
    }
    for tx in &doc.derivative_transactions {
        process_transaction(tables, clock, filing, idx, "derivative", tx);
        idx += 1;
    }

    // -- holdings (non-derivative then derivative) --
    let mut hidx = 0u64;
    for h in &doc.non_derivative_holdings {
        process_holding(tables, clock, filing, hidx, "non_derivative", h);
        hidx += 1;
    }
    for h in &doc.derivative_holdings {
        process_holding(tables, clock, filing, hidx, "derivative", h);
        hidx += 1;
    }

    // -- footnotes --
    for (i, f) in doc.footnotes.iter().enumerate() {
        let row = tables.create_row("ownership_footnotes", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("footnote_id", &f.id);
        row.set("text", &f.text);
    }

    // -- signatures --
    for (i, s) in doc.owner_signatures.iter().enumerate() {
        let row = tables.create_row("ownership_signatures", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("signature_name", &s.name);
        row.set("signature_date", &s.date);
    }
}

fn process_owner(tables: &mut Tables, clock: &Clock, filing: &Filing, i: u64, owner: &ReportingOwner) {
    let row = tables.create_row("reporting_owners", child_key(filing, i));
    set_filing_child(clock, filing, i, row);
    row.set("owner_cik", &owner.cik);
    row.set("owner_name", &owner.name);
    set_address(row, "owner_", owner.address.as_ref());
    let rel = owner.relationship.clone().unwrap_or_default();
    row.set("is_director", rel.is_director);
    row.set("is_officer", rel.is_officer);
    row.set("is_ten_percent_owner", rel.is_ten_percent_owner);
    row.set("is_other", rel.is_other);
    row.set("officer_title", &rel.officer_title);
    row.set("other_text", &rel.other_text);
}

fn process_transaction(
    tables: &mut Tables,
    clock: &Clock,
    filing: &Filing,
    i: u64,
    table_type: &str,
    tx: &Transaction,
) {
    let row = tables.create_row("ownership_transactions", child_key(filing, i));
    set_filing_child(clock, filing, i, row);
    row.set("table_type", table_type);
    row.set("security_title", &tx.security_title);
    row.set("transaction_date", &tx.transaction_date);
    row.set("deemed_execution_date", &tx.deemed_execution_date);
    row.set("transaction_form_type", &tx.transaction_form_type);
    row.set("transaction_code", &tx.transaction_code);
    row.set("equity_swap_involved", tx.equity_swap_involved);
    row.set("transaction_timeliness", &tx.transaction_timeliness);
    set_amount(row, "shares", "shares_num", &tx.shares);
    set_amount(row, "price_per_share", "price_per_share_num", &tx.price_per_share);
    row.set("acquired_disposed_code", &tx.acquired_disposed_code);
    set_amount(row, "shares_owned_following", "shares_owned_following_num", &tx.shares_owned_following);
    set_amount(row, "value_owned_following", "value_owned_following_num", &tx.value_owned_following);
    row.set("direct_or_indirect", &tx.direct_or_indirect);
    row.set("nature_of_ownership", &tx.nature_of_ownership);
    row.set("conversion_or_exercise_price", &tx.conversion_or_exercise_price);
    row.set("exercise_date", &tx.exercise_date);
    row.set("expiration_date", &tx.expiration_date);
    set_underlying(row, tx.underlying_security.as_ref());
    row.set("footnote_ids", join(&tx.footnote_ids));
}

fn process_holding(
    tables: &mut Tables,
    clock: &Clock,
    filing: &Filing,
    i: u64,
    table_type: &str,
    h: &Holding,
) {
    let row = tables.create_row("ownership_holdings", child_key(filing, i));
    set_filing_child(clock, filing, i, row);
    row.set("table_type", table_type);
    row.set("security_title", &h.security_title);
    set_amount(row, "shares_owned", "shares_owned_num", &h.shares_owned);
    row.set("direct_or_indirect", &h.direct_or_indirect);
    row.set("nature_of_ownership", &h.nature_of_ownership);
    row.set("conversion_or_exercise_price", &h.conversion_or_exercise_price);
    row.set("exercise_date", &h.exercise_date);
    row.set("expiration_date", &h.expiration_date);
    set_underlying(row, h.underlying_security.as_ref());
    row.set("footnote_ids", join(&h.footnote_ids));
}

fn set_underlying(row: &mut Row, u: Option<&crate::pb::pinax::sec::v1::UnderlyingSecurity>) {
    let d = crate::pb::pinax::sec::v1::UnderlyingSecurity::default();
    let u = u.unwrap_or(&d);
    row.set("underlying_title", &u.title);
    row.set("underlying_shares", &u.shares);
    row.set("underlying_value", &u.value);
}
