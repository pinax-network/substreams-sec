# SEC substreams endpoint (Pinax). Override per your deployment.
ENDPOINT ?= sec.substreams.pinax.network:443
# Local firehose-sec substreams tier1 (see firehose-sec/scripts/local-firehose.sh).
LOCAL_ENDPOINT ?= localhost:10016
# First streamable block for the `sec` chain (epoch bucket = unix_seconds / 600).
START_BLOCK ?= 2953156
STOP_BLOCK ?= +10
PARALLEL_JOBS ?= 100
# SEC block schema spkg (pinax.sec.v1), published by firehose-sec. Local copy is
# committed as firehose-sec.spkg (distinct from this package's own
# sec-v0.3.0.spkg output). Can be a release URL, e.g.
#   https://github.com/pinax-network/firehose-sec/releases/download/v0.3.0/sec-v0.3.0.spkg
SCHEMA_SPKG ?= ./spkg/firehose-sec.spkg
.DEFAULT_GOAL := pack

# Regenerate src/pb from the imported schema spkg (not from local .proto).
.PHONY: protogen
protogen:
	substreams protogen $(SCHEMA_SPKG) --exclude-paths="sf/substreams,google"

.PHONY: build
build:
	cargo build --target wasm32-unknown-unknown --release

.PHONY: pack
pack: build
	substreams pack -o ./spkg/{spkgDefaultName}

.PHONY: gui
gui: build
	substreams gui -e $(ENDPOINT) substreams.yaml db_out -s $(START_BLOCK)

.PHONY: run
run: build
	substreams run -e $(ENDPOINT) substreams.yaml db_out -s $(START_BLOCK) -t $(STOP_BLOCK)

.PHONY: prod
prod: build
	substreams run -e $(ENDPOINT) substreams.yaml db_out -s $(START_BLOCK) -t $(STOP_BLOCK) \
		--production-mode -H "X-Sf-Substreams-Parallel-Jobs: $(PARALLEL_JOBS)"

# Run against a LOCAL firehose-sec serve stack (plaintext, no auth).
# Bring the stack up first (in firehose-sec):
#   DATA_DIR=fh-10min-test ./scripts/local-firehose.sh --serve-only --with-substreams --start-block-num 2953156
.PHONY: run-local
run-local: build
	substreams run -e $(LOCAL_ENDPOINT) --plaintext substreams.yaml db_out -s $(START_BLOCK) -t $(STOP_BLOCK) -o jsonl

.PHONY: gui-local
gui-local: build
	substreams gui -e $(LOCAL_ENDPOINT) --plaintext substreams.yaml db_out -s $(START_BLOCK)
