-- Read view over state_companies — merges aggregate states into final values.
CREATE VIEW IF NOT EXISTS companies AS
SELECT
    cik,
    argMaxMerge(company_name)   AS company_name,
    groupUniqArrayMerge(forms)  AS forms,
    sum(filings)                AS filings,
    min(first_filing)           AS first_filing,
    max(last_filing)            AS last_filing
FROM state_companies
GROUP BY cik;
