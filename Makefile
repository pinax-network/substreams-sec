# Kalshi block schema spkg (pinax.kalshi.v1), published by firehose-kalshi.
# Local by default; can be a release URL, e.g.
#   https://github.com/pinax-network/firehose-kalshi/releases/download/v0.3.0/kalshi-v0.3.0.spkg
SCHEMA_SPKG ?= ./spkg/firehose-kalshi.spkg
.DEFAULT_GOAL := pack

# Regenerate src/pb from the imported schema spkg (not from a local .proto).
.PHONY: protogen
protogen:
	substreams protogen $(SCHEMA_SPKG) --exclude-paths sf/substreams,google

.PHONY: build
build:
	cargo build --target wasm32-unknown-unknown --release

.PHONY: test
test:
	cargo test

.PHONY: pack
pack: build schema
	substreams pack -o ./spkg/{spkgDefaultName}

.PHONY: info
info:
	substreams info ./spkg/{spkgDefaultName}

# Concatenate the numbered clickhouse/schema.*.sql layers (sort order) into the
# single schema.sql the sink loads. One blank line between files and none
# trailing, so substreams-sink-sql's naive `;` splitter never sees an empty
# final query. Pure awk — portable across BSD (macOS) and GNU.
.PHONY: schema
schema:
	awk 'FNR==1 && NR>1 {print ""} {print}' clickhouse/schema.*.sql > clickhouse/schema.sql