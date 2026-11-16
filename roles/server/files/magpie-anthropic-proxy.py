#!/usr/bin/env python3
"""Point Anthropic providers at a proxy. Leaves every other provider alone.

PATH PROXY updates that file and prints "updated" when it changes.
"- PROXY" reads JSON on stdin and, when it changes, writes JSON to stdout and
"updated" to stderr.
"--docker PROXY" reads and replaces /config/magpie/providers.json inside the
magpie container. The catalog is never written on the host.
"""

import json
import subprocess
import sys
from urllib.parse import urlparse

PROXY_HOSTS = {"api.anthropic.com"}
DOCKER_WRITE = (
    "umask 0077 && cat > /config/magpie/providers.json.tmp && "
    "chown 65532:65532 /config/magpie/providers.json.tmp && "
    "mv /config/magpie/providers.json.tmp /config/magpie/providers.json"
)


def anthropic(provider):
    if provider.get("preset") == "anthropic" or provider.get("id") in {"anthropic", "claude"}:
        return True
    for field in ("anthropic", "chat", "responses", "gemini"):
        host = urlparse(provider.get(field) or "").hostname
        if host in PROXY_HOSTS:
            return True
    return False


def apply_proxy(data, proxy):
    """Set proxy on Anthropic providers. Return True when data changed."""
    providers = data.get("providers") if isinstance(data, dict) else None
    if not isinstance(providers, list):
        return False
    changed = False
    for provider in providers:
        if not isinstance(provider, dict) or not anthropic(provider):
            continue
        if provider.get("proxy") == proxy:
            continue
        provider["proxy"] = proxy
        changed = True
    return changed


def dump(data):
    return json.dumps(data, indent=2) + "\n"


def write_docker(payload):
    subprocess.run(
        [
            "docker",
            "exec",
            "-i",
            "--user",
            "0",
            "magpie",
            "/bin/bash",
            "-c",
            DOCKER_WRITE,
        ],
        input=payload.encode(),
        check=True,
    )


def update_docker(proxy):
    raw = subprocess.check_output(
        ["docker", "exec", "magpie", "cat", "/config/magpie/providers.json"]
    )
    data = json.loads(raw)
    if not apply_proxy(data, proxy):
        return False
    write_docker(dump(data))
    return True


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) != 2:
        print("usage: magpie-anthropic-proxy.py PATH|--|-|--docker PROXY", file=sys.stderr)
        return 2
    target, proxy = argv
    if target == "--docker":
        if update_docker(proxy):
            print("updated")
        return 0
    if target == "-":
        data = json.load(sys.stdin)
        if not apply_proxy(data, proxy):
            return 0
        sys.stdout.write(dump(data))
        print("updated", file=sys.stderr)
        return 0
    with open(target, encoding="utf-8") as handle:
        data = json.load(handle)
    if not apply_proxy(data, proxy):
        return 0
    with open(target, "w", encoding="utf-8") as handle:
        handle.write(dump(data))
    print("updated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
