.PHONY: local

local:
	ansible-playbook playbook.yml --limit localhost --skip-tags "install"
