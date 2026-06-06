-- Read view over state_institutions.
CREATE VIEW IF NOT EXISTS institutions AS
SELECT
    manager_cik,
    argMaxMerge(manager_name)   AS manager_name,
    max(latest_period)          AS latest_period,
    argMaxMerge(latest_value)   AS latest_value,
    sum(reports)                AS reports,
    min(first_seen)             AS first_seen,
    max(last_seen)              AS last_seen
FROM state_institutions
GROUP BY manager_cik;
