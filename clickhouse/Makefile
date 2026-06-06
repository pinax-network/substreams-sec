ENDPOINT ?= sec.substreams.pinax.network:443
START_BLOCK ?= 2953156
STOP_BLOCK ?= +1000
DSN ?= clickhouse://default:@localhost:9000/default
.DEFAULT_GOAL := pack

# Concatenate schema.*.sql (sorted) into the single schema.sql the sink loads.
# Numbered prefixes enforce dependency order (0 = templates, 1 = tables).
.PHONY: schema
schema:
	@echo "-- This file is generated. Do not edit. Run 'make schema'." > schema.sql
	@echo "" >> schema.sql
	@for f in $$(ls schema.*.sql 2>/dev/null | sort); do \
		echo "-- >>> $$f" >> schema.sql; \
		cat "$$f" >> schema.sql; \
		echo "" >> schema.sql; \
	done
	@echo "wrote schema.sql"

.PHONY: db-pack
db-pack:
	$(MAKE) -C .. pack

.PHONY: pack
pack: schema db-pack
	substreams pack -o ../spkg/{spkgDefaultName}

# Create all tables in ClickHouse (run once).
.PHONY: setup
setup: pack
	substreams-sink-sql setup $(DSN) substreams.yaml

# Stream filings into ClickHouse.
.PHONY: dev
dev: pack
	substreams-sink-sql run $(DSN) substreams.yaml -e $(ENDPOINT) $(START_BLOCK):$(STOP_BLOCK) \
		--undo-buffer-size 0 --on-module-hash-mismatch=warn \
		--batch-block-flush-interval 1 --live-block-flush-interval 1 --infinite-retry
