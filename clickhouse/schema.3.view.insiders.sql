-- Read view over state_insiders.
CREATE VIEW IF NOT EXISTS insiders AS
SELECT
    owner_cik,
    argMaxMerge(owner_name) AS owner_name,
    uniqMerge(issuers)      AS issuers,
    sum(filings)            AS filings,
    max(ever_director)      AS ever_director,
    max(ever_officer)       AS ever_officer,
    max(ever_ten_pct)       AS ever_ten_pct,
    min(first_seen)         AS first_seen,
    max(last_seen)          AS last_seen
FROM state_insiders
GROUP BY owner_cik;
