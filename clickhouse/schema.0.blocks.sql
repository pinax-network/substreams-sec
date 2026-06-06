-- EDGAR 10-minute windows. block_num = epoch bucket (unix_seconds / 600).
CREATE TABLE IF NOT EXISTS blocks (
    block_num                   UInt64,
    block_hash                  String,
    timestamp                   DateTime(0, 'UTC'),
    minute                      UInt32 MATERIALIZED toRelativeMinuteNum(timestamp),
    feed_date                   String COMMENT 'YYYY-MM-DD UTC calendar day',

    PROJECTION prj_timestamp ( SELECT * ORDER BY timestamp )
)
ENGINE = ReplacingMergeTree
ORDER BY ( block_num )
SETTINGS deduplicate_merge_projection_mode = 'rebuild'
COMMENT 'EDGAR 10-minute windows';
