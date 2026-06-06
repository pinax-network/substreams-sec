//! Form 144 — notice of proposed sale of restricted/control securities.
//! Header + securities to be sold + securities sold in past 3 months.

use crate::pb::pinax::sec::v1::{Filing, Form144Notice};
use crate::{child_key, filing_key, join, set_address, set_amount, set_filing, set_filing_child};
use substreams::pb::substreams::Clock;
use substreams_database_change::tables::Tables;

pub fn process(tables: &mut Tables, clock: &Clock, filing: &Filing, notice: &Form144Notice) {
    // -- header --
    let row = tables.create_row("form144_notices", filing_key(filing));
    set_filing(clock, filing, row);
    row.set("filer_cik", &notice.filer_cik);

    let issuer = notice.issuer.clone().unwrap_or_default();
    row.set("issuer_cik", &issuer.issuer_cik);
    row.set("issuer_name", &issuer.issuer_name);
    row.set("sec_file_number", &issuer.sec_file_number);
    set_address(row, "issuer_", issuer.issuer_address.as_ref());
    row.set("issuer_contact_phone", &issuer.issuer_contact_phone);
    row.set("person_for_whose_account", &issuer.person_for_whose_account);
    row.set("relationships_to_issuer", join(&issuer.relationships_to_issuer));

    let sec_info = notice.securities_information.clone().unwrap_or_default();
    row.set("securities_class_title", &sec_info.securities_class_title);
    let broker = sec_info.broker.clone().unwrap_or_default();
    row.set("broker_name", &broker.name);
    set_address(row, "broker_", broker.address.as_ref());
    set_amount(row, "units_sold", "units_sold_num", &sec_info.units_sold);
    set_amount(row, "aggregate_market_value", "aggregate_market_value_num", &sec_info.aggregate_market_value);
    set_amount(row, "units_outstanding", "units_outstanding_num", &sec_info.units_outstanding);
    row.set("approx_sale_date", &sec_info.approx_sale_date);
    row.set("securities_exchange_name", &sec_info.securities_exchange_name);

    row.set("nothing_sold_past_3_months", notice.nothing_sold_past_3_months);
    row.set("remarks", &notice.remarks);
    let sig = notice.signature.clone().unwrap_or_default();
    row.set("notice_date", &sig.notice_date);
    row.set("signature", &sig.signature);

    // -- securities to be sold --
    for (i, s) in notice.securities_to_be_sold.iter().enumerate() {
        let row = tables.create_row("form144_securities_to_be_sold", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("securities_class_title", &s.securities_class_title);
        row.set("acquired_date", &s.acquired_date);
        row.set("nature_of_acquisition", &s.nature_of_acquisition);
        row.set("acquired_from", &s.acquired_from);
        row.set("is_gift", s.is_gift);
        set_amount(row, "amount_acquired", "amount_acquired_num", &s.amount_acquired);
        row.set("payment_date", &s.payment_date);
        row.set("nature_of_payment", &s.nature_of_payment);
    }

    // -- securities sold in past 3 months --
    for (i, s) in notice.securities_sold_past_3_months.iter().enumerate() {
        let row = tables.create_row("form144_securities_sold_past_3_months", child_key(filing, i as u64));
        set_filing_child(clock, filing, i as u64, row);
        row.set("seller_name", &s.seller_name);
        set_address(row, "seller_", s.seller_address.as_ref());
        row.set("securities_class_title", &s.securities_class_title);
        row.set("sale_date", &s.sale_date);
        set_amount(row, "amount_sold", "amount_sold_num", &s.amount_sold);
        set_amount(row, "gross_proceeds", "gross_proceeds_num", &s.gross_proceeds);
    }
}
