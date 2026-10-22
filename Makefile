# Kalshi block schema spkg (pinax.kalshi.v1), published by firehose-kalshi.
# Local by default; can be a release URL, e.g.
#   https://github.com/pinax-network/firehose-kalshi/releases/download/v0.3.0/kalshi-v0.3.0.spkg
SCHEMA_SPKG ?= ./spkg/firehose-kalshi.spkg
.DEFAULT_GOAL := pack

# Public SEC tier1 endpoint. Needs no auth — note a stale SUBSTREAMS_API_TOKEN
# in the environment is actively rejected (unset it if `gui`/`dev` 401s).
ENDPOINT ?= sec.substreams.riv-stage-firehose-a.pinax.io:443
# 12233 is the chain's first streamable block.
START_BLOCK ?= 18227
STOP_BLOCK  ?= +1000
# ClickHouse sink target. Override for a remote server, e.g.
#   DSN=clickhouse://user:pass@host:9000/db
DSN ?= clickhouse://default:@localhost:9000/default

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

# Open the GUI against the public SEC endpoint to manually test the stream.
# `env -u` drops the auth vars so a stale token can't trigger Unauthenticated.
.PHONY: gui
gui:
	substreams gui -e $(ENDPOINT) substreams.yaml db_out -s $(START_BLOCK)

# Concatenate the numbered clickhouse/schema.*.sql layers (sort order) into the
# single schema.sql the sink loads. One blank line between files and none
# trailing, so substreams-sink-sql's naive `;` splitter never sees an empty
# final query. Pure awk — portable across BSD (macOS) and GNU.
.PHONY: schema
schema:
	awk 'FNR==1 && NR>1 {print ""} {print}' clickhouse/schema.*.sql > clickhouse/schema.sql

# Create the ClickHouse tables/MVs/views from clickhouse/schema.sql. Run once.
.PHONY: setup
setup: schema
	substreams-sink-sql setup "$(DSN)" substreams.yaml

# Stream db_out into ClickHouse over the range START_BLOCK:STOP_BLOCK.
.PHONY: dev
dev:
	substreams-sink-sql run "$(DSN)" substreams.yaml "$(START_BLOCK):$(STOP_BLOCK)" -e $(ENDPOINT)