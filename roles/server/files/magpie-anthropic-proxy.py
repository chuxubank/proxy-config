#!/usr/bin/env python3
"""Point Anthropic providers at a proxy. Leaves every other provider alone."""

import json
import sys
from urllib.parse import urlparse

PROXY_HOSTS = {"api.anthropic.com"}


def anthropic(provider):
    if provider.get("preset") == "anthropic" or provider.get("id") in {"anthropic", "claude"}:
        return True
    for field in ("anthropic", "chat", "responses", "gemini"):
        host = urlparse(provider.get(field) or "").hostname
        if host in PROXY_HOSTS:
            return True
    return False


def main():
    path, proxy = sys.argv[1], sys.argv[2]
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    providers = data.get("providers")
    if not isinstance(providers, list):
        return
    changed = False
    for provider in providers:
        if not isinstance(provider, dict) or not anthropic(provider):
            continue
        if provider.get("proxy") == proxy:
            continue
        provider["proxy"] = proxy
        changed = True
    if not changed:
        return
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")
    print("updated")


if __name__ == "__main__":
    main()
