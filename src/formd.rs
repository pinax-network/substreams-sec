//! Form D — notice of exempt offering (Reg D). Header (issuer + offering) +
//! related persons.

use crate::pb::pinax::sec::v1::{Filing, FormDNotice};
use crate::{child_key, filing_key, join, set_address, set_amount, set_filing, set_filing_child};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::Tables;

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, notice: &FormDNotice) {
    // -- header --
    let row = tables.create_row("formd_notices", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("schema_version", &notice.schema_version);
    row.set("submission_type", &notice.submission_type);

    let issuer = notice.primary_issuer.clone().unwrap_or_default();
    row.set("issuer_cik", &issuer.cik);
    row.set("entity_name", &issuer.entity_name);
    set_address(row, "issuer_", issuer.address.as_ref());
    row.set("phone", &issuer.phone);
    row.set("jurisdiction_of_inc", &issuer.jurisdiction_of_inc);
    row.set("entity_type", &issuer.entity_type);
    row.set("year_of_inc", &issuer.year_of_inc);

    let o = notice.offering.clone().unwrap_or_default();
    row.set("industry_group", &o.industry_group);
    row.set("offering_is_amendment", o.is_amendment);
    row.set("date_of_first_sale", &o.date_of_first_sale);
    row.set("more_than_one_year", o.more_than_one_year);
    row.set("is_equity_type", o.is_equity_type);
    row.set("federal_exemptions", join(&o.federal_exemptions));
    set_amount(row, "minimum_investment", "minimum_investment_num", &o.minimum_investment);
    set_amount(row, "total_offering_amount", "total_offering_amount_num", &o.total_offering_amount);
    set_amount(row, "total_amount_sold", "total_amount_sold_num", &o.total_amount_sold);
    set_amount(row, "total_remaining", "total_remaining_num", &o.total_remaining);
    row.set("has_non_accredited_investors", o.has_non_accredited_investors);
    set_amount(row, "total_already_invested", "total_already_invested_num", &o.total_already_invested);
    set_amount(row, "sales_commissions", "sales_commissions_num", &o.sales_commissions);
    set_amount(row, "finders_fees", "finders_fees_num", &o.finders_fees);
    set_amount(row, "gross_proceeds_used", "gross_proceeds_used_num", &o.gross_proceeds_used);
    row.set("related_person_count", notice.related_persons.len() as u32);

    // -- related persons --
    for (i, p) in notice.related_persons.iter().enumerate() {
        let row = tables.create_row("formd_related_persons", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("first_name", &p.first_name);
        row.set("middle_name", &p.middle_name);
        row.set("last_name", &p.last_name);
        set_address(row, "", p.address.as_ref());
        row.set("relationships", join(&p.relationships));
        row.set("relationship_clarification", &p.relationship_clarification);
    }
}
