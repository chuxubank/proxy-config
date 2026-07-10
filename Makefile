.DEFAULT_GOAL := help

export ANSIBLE_CONFIG := ansible.cfg

PLAYBOOK    ?= playbook.yml
LIMIT       ?=
TAGS        ?=
SKIP_TAGS   ?=
EXTRA       ?=

# Assemble optional flags only when the matching variable is set.
LIMIT_FLAG       = $(if $(LIMIT),--limit $(LIMIT),)
TAGS_FLAG        = $(if $(TAGS),--tags $(TAGS),)
SKIP_TAGS_FLAG   = $(if $(SKIP_TAGS),--skip-tags $(SKIP_TAGS),)
CHECK_FLAGS      = $(LIMIT_FLAG) $(TAGS_FLAG) $(SKIP_TAGS_FLAG) $(EXTRA)
ROLE_FLAGS       = $(TAGS_FLAG) $(SKIP_TAGS_FLAG) $(EXTRA)
ANSIBLE_PLAYBOOK = ansible-playbook $(PLAYBOOK)

.PHONY: help deps syntax check diff local local-install server pve openwrt pull lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

deps: ## Install Galaxy role/collection requirements
	ansible-galaxy install -r requirements.yml

syntax: ## Fast parse validation without querying dynamic inventory
	$(ANSIBLE_PLAYBOOK) --inventory inventory.yml --syntax-check $(EXTRA)

check: ## Dry-run against the inventory (no changes)
	$(ANSIBLE_PLAYBOOK) --check $(CHECK_FLAGS)

diff: ## Dry-run with a diff of proposed changes
	$(ANSIBLE_PLAYBOOK) --check --diff $(CHECK_FLAGS)

local: ## Apply workstation changes, skipping binary installs
	$(ANSIBLE_PLAYBOOK) --limit localhost --skip-tags install $(ROLE_FLAGS)

local-install: ## Apply workstation changes including binary installs
	$(ANSIBLE_PLAYBOOK) --limit localhost $(ROLE_FLAGS)

server: ## Deploy to the VPS group
	$(ANSIBLE_PLAYBOOK) --limit vps_group $(ROLE_FLAGS)

pve: ## Apply the Proxmox play
	$(ANSIBLE_PLAYBOOK) --inventory inventory.yml --limit pve_group $(EXTRA)

openwrt: ## Apply the OpenWrt play
	$(ANSIBLE_PLAYBOOK) --limit OpenWrt $(EXTRA)

pull: ## Pull Docker Compose images on the server
	$(ANSIBLE_PLAYBOOK) --limit vps_group --tags pull $(EXTRA)

lint: ## Run ansible-lint if available
	@command -v ansible-lint >/dev/null 2>&1 \
		&& ansible-lint $(PLAYBOOK) \
		|| echo "ansible-lint not installed; skipping"
