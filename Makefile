# SEC block schema spkg (pinax.sec.v1), published by firehose-sec.
# Local by default; can be a release URL, e.g.
#   https://github.com/pinax-network/firehose-sec/releases/download/v0.3.0/sec-v0.3.0.spkg
SCHEMA_SPKG ?= ./spkg/firehose-sec.spkg

# Substreams endpoint (firehose-sec-backed tier). Override for prod; a local
# firehose-sec serve is :10016 plaintext.
ENDPOINT ?= sec.substreams.pinax.network:443
LOCAL_ENDPOINT ?= localhost:10016
START_BLOCK ?= 2953156
STOP_BLOCK ?= +10
DSN ?= clickhouse://default:@localhost:9000/default
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

# Concatenate the numbered clickhouse/schema.*.sql layers (sort order) into the
# single clickhouse/schema.sql the sink loads. One blank line between files and
# none trailing, so substreams-sink-sql's naive `;` splitter never sees an empty
# final query. Pure awk — portable across BSD (macOS) and GNU.
.PHONY: schema
schema:
	awk 'FNR==1 && NR>1 {print ""} {print}' clickhouse/schema.*.sql > clickhouse/schema.sql

.PHONY: pack
pack: build schema
	substreams pack -o ./spkg/sec-v0.3.0.spkg

.PHONY: info
info:
	substreams info ./spkg/sec-v0.3.0.spkg

# Create the ClickHouse tables from the packaged schema (run once).
.PHONY: setup
setup: pack
	substreams-sink-sql setup $(DSN) substreams.yaml

# Stream filings into ClickHouse.
.PHONY: dev
dev: pack
	substreams-sink-sql run $(DSN) substreams.yaml -e $(ENDPOINT) $(START_BLOCK):$(STOP_BLOCK) \
		--undo-buffer-size 0 --on-module-hash-mismatch=warn \
		--batch-block-flush-interval 1 --live-block-flush-interval 1 --infinite-retry

# Run db_out against a local firehose-sec serve (plaintext, no auth).
.PHONY: run-local
run-local: build
	substreams run -e $(LOCAL_ENDPOINT) --plaintext substreams.yaml db_out -s $(START_BLOCK) -t $(STOP_BLOCK) -o jsonl

.PHONY: gui-local
gui-local: build
	substreams gui -e $(LOCAL_ENDPOINT) --plaintext substreams.yaml db_out -s $(START_BLOCK)
