//! Form C — Regulation Crowdfunding offering statement. Header (issuer +
//! intermediary + offering terms).

use crate::pb::pinax::sec::v1::{Filing, FormCNotice};
use crate::{filing_key, set_address, set_amount, set_filing};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::Tables;

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, notice: &FormCNotice) {
    let row = tables.create_row("formc_notices", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("filer_cik", &notice.filer_cik);

    let issuer = notice.issuer.clone().unwrap_or_default();
    row.set("issuer_name", &issuer.name);
    row.set("legal_status_form", &issuer.legal_status_form);
    row.set("jurisdiction", &issuer.jurisdiction);
    row.set("date_incorporation", &issuer.date_incorporation);
    set_address(row, "issuer_", issuer.address.as_ref());
    row.set("website", &issuer.website);

    row.set("intermediary_company_name", &notice.intermediary_company_name);
    row.set("intermediary_cik", &notice.intermediary_cik);
    row.set("intermediary_file_number", &notice.intermediary_file_number);

    let o = notice.offering.clone().unwrap_or_default();
    row.set("security_type", &o.security_type);
    row.set("num_securities_offered", &o.num_securities_offered);
    set_amount(row, "price", "price_num", &o.price);
    set_amount(row, "offering_amount", "offering_amount_num", &o.offering_amount);
    set_amount(row, "maximum_offering_amount", "maximum_offering_amount_num", &o.maximum_offering_amount);
    row.set("over_subscription_accepted", o.over_subscription_accepted);
    row.set("deadline_date", &o.deadline_date);
    set_amount(row, "compensation_amount", "compensation_amount_num", &o.compensation_amount);
}
