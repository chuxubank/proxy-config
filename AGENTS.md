# Repository Guidelines

## Project Structure & Module Organization
The root `playbook.yml` stitches together roles for `localhost`, VPS, and Proxmox/OpenWrt targets. Hosts come from the static `inventory.yml` plus the dynamic `inventory.proxmox.yml` (both wired in via `ansible.cfg`).
Shared variables live in `group_vars/{local_group,vps_group,xray_group,pve_group,openwrt_group}.yml`, while host-specific overrides belong in `host_vars/<host>.yml` (e.g. `host_vars/bwg-cn2-gia.yml`).
Implementation details are split into roles: `roles/common` handles base packages and Homebrew/Docker setup, `roles/server` provisions the upstream proxy (Caddy, Xray, monitoring, RSS) via Docker Compose, `roles/{xray_client,sing-box_client}` manage local client configs, and `roles/{pve_openwrt,arch_bootstrap}` cover homelab bootstrap flows.
Keep templates, handlers, and files under the standard Ansible role layout.

## Build, Test, and Development Commands
Common workflows are wrapped in the `Makefile` (run `make help` to list targets); it exports `ANSIBLE_CONFIG=ansible.cfg` and accepts `LIMIT`/`TAGS`/`SKIP_TAGS`/`EXTRA` overrides.
- `make deps` (or `ansible-galaxy install -r requirements.yml`) — pulls the `geerlingguy.docker` dependency into the gitignored `.ansible/` cache before any run.
- `make local` — applies workstation changes to `localhost`, skipping the `install` tag; `make local-install` includes binary installs.
- `make server` / `make pull` — deploy to `vps_group` / pull Docker Compose images on the server.
- `make check` / `make diff` — dry-run (with diff) against the inventory to validate proposed edits.
- `make syntax` — fast parse validation for CI hooks or pre-commit checks.

## Coding Style & Naming Conventions
Use YAML with two-space indentation and wrap lines before 120 chars. Variables follow `snake_case`, secrets end with `_token` or `_password`, and inventory group names should mirror their directory names for clarity. Templates live in `roles/<role>/templates/*.j2` and should emit JSON or TOML formatted with the same spacing seen in existing client configs. Prefer `block` + `when` constructs over long `when` chains, and keep tasks idempotent by using `creates`, `changed_when`, or module checks.

## Testing Guidelines
Run `ansible-playbook playbook.yml --check --diff` before opening a PR; the diff should show only the intended mutations. Use `ANSIBLE_STDOUT_CALLBACK=yaml` locally when debugging to match how logs are scrubbed in `~/Library/Logs/{xray,sing-box}`. When adding templates, validate them with the vendor binaries (see `README.org` for `xray run -confdir…` and `sing-box check -C…`). There is no dedicated coverage target, but every new role task must either be touched by an existing host in `inventory.yml` or accompanied by a temporary molecule-style harness.

## Commit & Pull Request Guidelines
Follow the existing Conventional Commit pattern (`type(scope): summary`), e.g., `fix(service): configure environment and adjust sudo usage`. Commits should be scoped per role or inventory change to keep rollbacks simple. Pull requests need: a high-level description, the exact command used to test (include `--limit` if applicable), linked issues or TODO references, and screenshots or log excerpts when touching client configs so reviewers can confirm runtime behavior.

## Security & Configuration Tips
Runtime secrets are pulled from `pass` via `community.general.passwordstore` lookups; store their entry paths as `*_pass_path` inventory vars (see `inventory.yml`) rather than committing values. Rendered files that hold secrets (`.env`, client configs) are written with `mode: "0600"`; files bind-mounted into containers and read by a non-root process (e.g. `xray/config.json`) must stay `0644` or the container hits `permission denied`. Never commit personal certificates, the regenerable `.ansible/` cache, or logs from `~/Library/Logs`. When experimenting with new providers, create a dedicated `group_vars/<new_group>.yml` and guard it behind inventory groups so accidental deployments do not leak.
