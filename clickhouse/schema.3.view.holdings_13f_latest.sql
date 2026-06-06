-- Read view over state_holdings_13f_latest — latest position per manager+cusip.
CREATE VIEW IF NOT EXISTS holdings_13f_latest AS
SELECT
    manager_cik,
    cusip,
    argMaxMerge(issuer_name)        AS issuer_name,
    argMaxMerge(title_of_class)     AS title_of_class,
    argMaxMerge(value)              AS value,
    argMaxMerge(shares)             AS shares,
    argMaxMerge(accession_number)   AS accession_number,
    max(as_of)                      AS as_of
FROM state_holdings_13f_latest
GROUP BY manager_cik, cusip;
