# Repository Guidelines

## Project Structure & Module Organization
The root `playbook.yml` stitches together roles for `localhost` and VPS targets defined in `inventory.yml`.
Shared variables live in `group_vars/{local_group,vps_group,xray_group}.yml`, while host-specific overrides belong in `host_vars/nerd.yml`.
Implementation details are split into roles: `roles/common` handles base packages and users, `roles/server` provisions the upstream proxy, and `roles/{xray_client,sing-box_client}` manage local client configs.
Keep templates, handlers, and files under the standard Ansible role layout.

## Build, Test, and Development Commands
- `ansible-galaxy install -r requirements.yml` — pulls the `geerlingguy.docker` dependency before any run.
- `ANSIBLE_CONFIG=ansible.cfg ansible-playbook playbook.yml --limit localhost` — applies workstation changes.
- `ansible-playbook playbook.yml --check` — dry-run against the full inventory to validate proposed edits.
- `ansible-playbook playbook.yml --syntax-check` — fast parse validation for CI hooks or pre-commit checks.

## Coding Style & Naming Conventions
Use YAML with two-space indentation and wrap lines before 120 chars. Variables follow `snake_case`, secrets end with `_token` or `_password`, and inventory group names should mirror their directory names for clarity. Templates live in `roles/<role>/templates/*.j2` and should emit JSON or TOML formatted with the same spacing seen in existing client configs. Prefer `block` + `when` constructs over long `when` chains, and keep tasks idempotent by using `creates`, `changed_when`, or module checks.

## Testing Guidelines
Run `ansible-playbook playbook.yml --check --diff` before opening a PR; the diff should show only the intended mutations. Use `ANSIBLE_STDOUT_CALLBACK=yaml` locally when debugging to match how logs are scrubbed in `~/Library/Logs/{xray,sing-box}`. When adding templates, validate them with the vendor binaries (see `README.org` for `xray run -confdir…` and `sing-box check -C…`). There is no dedicated coverage target, but every new role task must either be touched by an existing host in `inventory.yml` or accompanied by a temporary molecule-style harness.

## Commit & Pull Request Guidelines
Follow the existing Conventional Commit pattern (`type(scope): summary`), e.g., `fix(service): configure environment and adjust sudo usage`. Commits should be scoped per role or inventory change to keep rollbacks simple. Pull requests need: a high-level description, the exact command used to test (include `--limit` if applicable), linked issues or TODO references, and screenshots or log excerpts when touching client configs so reviewers can confirm runtime behavior.

## Security & Configuration Tips
Keep credentials out of plain YAML; prefer `ansible-vault encrypt host_vars/nerd.yml` for secrets. Never commit personal certificates or logs from `~/Library/Logs`. When experimenting with new providers, create a dedicated `group_vars/<new_group>.yml` and guard it behind inventory groups so accidental deployments do not leak.
