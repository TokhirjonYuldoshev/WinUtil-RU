#!/usr/bin/env python3
"""Synchronize only marked release-status sections from verified GitHub releases."""
import argparse
import json
import os
from pathlib import Path
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

REPO = "TokhirjonYuldoshev/WinUtil-RU"
UPSTREAM = "ChrisTitusTech/winutil"
ALLOWED = ("README.md", "README.en.md", "docs/README-RU.md",
           "docs/AUTOMATION-RU.md", "docs/AUDIT-RU.md")
SHA = re.compile(r"^[0-9a-f]{40}$")
HASH = re.compile(r"^sha256:[0-9a-f]{64}$")
RU_TAG = re.compile(r"^([0-9]{2}\.[0-9]{2}\.[0-9]{2})-RU\.[1-9][0-9]*$")
MARKED = re.compile(
    r"(?ms)^<!-- WINUTIL-RU-DOCSYNC:BEGIN stable=([^\s]+) upstream=([^\s]+) -->\n"
    r".*?^<!-- WINUTIL-RU-DOCSYNC:END -->"
)


def api(path):
    if not path.startswith(("/repos/" + REPO + "/", "/repos/" + UPSTREAM + "/")):
        raise ValueError("Forbidden API host/path")
    token = os.environ.get("GH_TOKEN", "")
    if not token:
        raise RuntimeError("GH_TOKEN is required")
    req = urllib.request.Request(
        "https://api.github.com" + path,
        headers={"Accept": "application/vnd.github+json",
                 "Authorization": "Bearer " + token,
                 "User-Agent": "WinUtil-RU-Documentation-Sync",
                 "X-GitHub-Api-Version": "2022-11-28"},
    )
    with urllib.request.urlopen(req, timeout=25) as response:
        return json.load(response)


def snapshot():
    stable = api("/repos/" + REPO + "/releases/latest")
    official = api("/repos/" + UPSTREAM + "/releases/latest")
    tag = stable.get("tag_name", "")
    match = RU_TAG.fullmatch(tag)
    if not match or stable.get("draft") or stable.get("prerelease"):
        raise ValueError("GitHub did not return a published RU stable release")
    base = match.group(1)
    official_tag = official.get("tag_name", "")
    if not re.fullmatch(r"[0-9]{2}\.[0-9]{2}\.[0-9]{2}", official_tag):
        raise ValueError("Official latest stable tag has invalid format")
    if official.get("draft") or official.get("prerelease"):
        raise ValueError("Official latest release is not stable")
    pinned = api("/repos/" + UPSTREAM + "/releases/tags/" +
                 urllib.parse.quote(base, safe=""))
    if pinned.get("draft") or pinned.get("prerelease"):
        raise ValueError("RU baseline is not a published official stable")
    ref = api("/repos/" + REPO + "/commits/" +
              urllib.parse.quote(tag, safe=""))
    commit = ref.get("sha", "").lower()
    if not SHA.fullmatch(commit):
        raise ValueError("Invalid stable tag commit")
    target = stable.get("target_commitish", "").lower()
    if SHA.fullmatch(target) and commit != target:
        raise ValueError("Release target and stable tag commit disagree")
    assets = {item["name"]: item for item in stable.get("assets", [])}
    if {"winutil-RU.ps1", "release.json", "LICENSE"} - assets.keys():
        raise ValueError("Required stable assets missing")
    digest = assets["winutil-RU.ps1"].get("digest", "")
    if not HASH.fullmatch(digest):
        raise ValueError("Missing verified GitHub asset SHA256")
    if any(assets[key].get("size", 0) < 1 for key in
           ("winutil-RU.ps1", "release.json", "LICENSE")):
        raise ValueError("Empty release asset")
    return {"tag": tag, "base": base, "official": official_tag,
            "commit": commit, "digest": digest.removeprefix("sha256:")}


def block(path, info):
    tag, base, upstream = info["tag"], info["base"], info["official"]
    stable_url = "https://github.com/" + REPO + "/releases/tag/" + tag
    official_url = "https://github.com/" + UPSTREAM + "/releases/tag/" + upstream
    tick = chr(96)
    if path == "README.en.md":
        lines = [
            "**Published WinUtil-RU stable:** [" + tag + "](" + stable_url + ").",
            "**Official WinUtil baseline:** " + tick + base + tick + "; "
            "[latest upstream stable](" + official_url + "): " + tick + upstream + tick + ".",
            "**Immutable release commit:** " + tick + info["commit"] + tick + ".",
            "**GitHub asset SHA256 (winutil-RU.ps1):** " +
            tick + info["digest"] + tick + ".",
            "For a pinned executable download the published release asset; "
            "the bootstrap tracks the current russian source branch.",
            "*GitHub Releases metadata, not proof of manual Windows QA. "
            "Historical CI and QA evidence remains in the audit.*",
        ]
    else:
        lines = [
            "**Опубликованный stable WinUtil-RU:** [" + tag + "](" + stable_url + ").",
            "**Официальная основа:** " + tick + base + tick + "; "
            "[последний upstream stable](" + official_url + "): " +
            tick + upstream + tick + ".",
            "**Неизменяемый commit тега:** " + tick + info["commit"] + tick + ".",
            "**SHA256 опубликованного winutil-RU.ps1:** " +
            tick + info["digest"] + tick + ".",
            "Для точной версии скачивайте release asset; загрузчик следует "
            "текущей ветке russian.",
            "*Метаданные GitHub Releases, а не подтверждение ручного Windows QA. "
            "Исторические результаты CI и QA сохраняются отдельно.*",
        ]
    header = "<!-- WINUTIL-RU-DOCSYNC:BEGIN stable=" + tag + " upstream=" + upstream + " -->"
    return header + "\n\n" + "\n\n".join(lines) + "\n\n<!-- WINUTIL-RU-DOCSYNC:END -->"


def update(root, info, check=False):
    changed = []
    for name in ALLOWED:
        file = root / name
        original = file.read_text(encoding="utf-8")
        matches = list(MARKED.finditer(original))
        if len(matches) != 1:
            raise ValueError(name + ": exactly one managed section required")
        match = matches[0]
        old_key = match.group(1), match.group(2)
        new_key = info["tag"], info["official"]
        if old_key == new_key:
            continue  # Do not rewrite approved prose without new release metadata.
        replacement = original[:match.start()] + block(name, info) + original[match.end():]
        if replacement != original:
            changed.append(name)
            if not check:
                file.write_text(replacement, encoding="utf-8", newline="")
    return changed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        info = snapshot()
        changed = update(args.root, info, check=args.check)
    except (ValueError, RuntimeError, OSError, urllib.error.URLError) as error:
        print("Documentation sync blocked: " + str(error), file=sys.stderr)
        return 2
    print("Stable: " + info["tag"] + "; upstream: " + info["official"])
    print("Modified docs: " + (", ".join(changed) if changed else "none"))
    return 1 if args.check and changed else 0


if __name__ == "__main__":
    sys.exit(main())
