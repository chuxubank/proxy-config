.DEFAULT_GOAL := help

export ANSIBLE_CONFIG := ansible.cfg

PLAYBOOK    ?= playbook.yml
LIMIT       ?=
TAGS        ?=
SKIP_TAGS   ?=
EXTRA       ?=

# Assemble optional flags only when the matching variable is set.
LIMIT_FLAG     = $(if $(LIMIT),--limit $(LIMIT),)
TAGS_FLAG      = $(if $(TAGS),--tags $(TAGS),)
SKIP_TAGS_FLAG = $(if $(SKIP_TAGS),--skip-tags $(SKIP_TAGS),)
PLAY           = ansible-playbook $(PLAYBOOK) $(LIMIT_FLAG) $(TAGS_FLAG) $(SKIP_TAGS_FLAG) $(EXTRA)

.PHONY: help deps syntax check diff local local-install server pull lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

deps: ## Install Galaxy role/collection requirements
	ansible-galaxy install -r requirements.yml

syntax: ## Fast parse validation of the playbook
	$(PLAY) --syntax-check

check: ## Dry-run against the inventory (no changes)
	$(PLAY) --check

diff: ## Dry-run with a diff of proposed changes
	$(PLAY) --check --diff

local: ## Apply workstation changes, skipping binary installs
	ansible-playbook $(PLAYBOOK) --limit localhost --skip-tags install $(TAGS_FLAG) $(EXTRA)

local-install: ## Apply workstation changes including binary installs
	ansible-playbook $(PLAYBOOK) --limit localhost $(TAGS_FLAG) $(EXTRA)

server: ## Deploy to the VPS group
	$(PLAY) --limit vps_group

pull: ## Pull Docker Compose images on the server
	$(PLAY) --limit vps_group --tags pull

lint: ## Run ansible-lint if available
	@command -v ansible-lint >/dev/null 2>&1 \
		&& ansible-lint $(PLAYBOOK) \
		|| echo "ansible-lint not installed; skipping"
