ENDPOINT ?= monorail.proxy.rlwy.net:16025
# First streamable block for the `sec` chain (epoch bucket = unix_seconds / 600).
START_BLOCK ?= 2953156
STOP_BLOCK ?= +10
PARALLEL_JOBS ?= 100
.DEFAULT_GOAL := pack

.PHONY: build
build:
	cargo build --target wasm32-unknown-unknown --release

.PHONY: pack
pack: build
	substreams pack -o ./spkg/{spkgDefaultName}

.PHONY: gui
gui: build
	substreams gui -e $(ENDPOINT) substreams.yaml db_out -s $(START_BLOCK) --plaintext

.PHONY: run
run: build
	substreams run -e $(ENDPOINT) substreams.yaml db_out -s $(START_BLOCK) -t $(STOP_BLOCK) --plaintext

.PHONY: prod
prod: build
	substreams run -e $(ENDPOINT) substreams.yaml db_out -s $(START_BLOCK) -t $(STOP_BLOCK) \
		--production-mode -H "X-Sf-Substreams-Parallel-Jobs: $(PARALLEL_JOBS)" --plaintext
