#!/usr/bin/env python3
"""Update versions.json, README.md current-versions block, and CHANGELOG.md.

Designed to be run by the daily CI workflow after a green build, smoke test,
and vulnerability scan. Sanitizes upstream release notes so tracked files
never violate .github/scripts/public-check.sh.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

def load_forbidden_regex() -> re.Pattern[str] | None:
    """Read the FORBIDDEN regex from .github/scripts/public-check.sh."""
    script = Path(".github/scripts/public-check.sh")
    if not script.exists():
        return None
    for line in script.read_text(encoding="utf-8").splitlines():
        if line.startswith("FORBIDDEN='") and line.endswith("'"):
            return re.compile(line[len("FORBIDDEN='") : -1], re.IGNORECASE)
    return None


FORBIDDEN_RE = load_forbidden_regex()


def sanitize_notes(raw: str, max_lines: int = 8) -> list[str]:
    """Return safe, concise bullet lines extracted from upstream release notes."""
    out: list[str] = []
    for line in raw.splitlines():
        s = line.strip()
        if not s:
            continue
        if FORBIDDEN_RE and FORBIDDEN_RE.search(s):
            continue
        if s.startswith(("- ", "* ")):
            item = s[2:].strip()
        elif s.startswith("### ") or s.startswith("## "):
            continue
        else:
            item = s
        if len(item) > 180:
            item = item[:177].rstrip() + "..."
        out.append(item)
        if len(out) >= max_lines:
            break
    return out


def main() -> int:
    if len(sys.argv) < 4:
        print("Usage: update-docs.py <versions.new.json> <upstream-changes.md> <cve-diff.json>", file=sys.stderr)
        return 2

    new_versions_path = Path(sys.argv[1])
    upstream_changes_path = Path(sys.argv[2])
    cve_diff_path = Path(sys.argv[3])

    versions_path = Path("versions.json")
    readme_path = Path("README.md")
    changelog_path = Path("CHANGELOG.md")

    old_data = json.loads(versions_path.read_text(encoding="utf-8")) if versions_path.exists() else {}
    new_data = json.loads(new_versions_path.read_text(encoding="utf-8"))
    cve_diff = json.loads(cve_diff_path.read_text(encoding="utf-8")) if cve_diff_path.exists() else {}
    upstream_notes_raw = upstream_changes_path.read_text(encoding="utf-8") if upstream_changes_path.exists() else ""

    # Preserve last_digest if this run did not publish (e.g. Hub secrets not yet set).
    if not new_data.get("last_digest") and old_data.get("last_digest"):
        new_data["last_digest"] = old_data["last_digest"]

    build_date = new_data.get("last_build_date", "")
    upstream_ver = new_data.get("upstream_version", "")
    debian_ver = new_data.get("debian_version", "13")
    components: dict[str, str] = new_data.get("components", {})
    fixed_cves: list[str] = cve_diff.get("fixed_cves", [])
    unfixed_list: list[str] = new_data.get("unfixed_high_critical", [])

    # Determine whether anything meaningful changed compared to committed versions.json.
    old_cmp = {
        "upstream_version": old_data.get("upstream_version"),
        "debian_version": old_data.get("debian_version"),
        "components": old_data.get("components"),
        "last_digest": old_data.get("last_digest"),
        "unfixed_high_critical": old_data.get("unfixed_high_critical"),
    }
    new_cmp = {
        "upstream_version": new_data.get("upstream_version"),
        "debian_version": new_data.get("debian_version"),
        "components": new_data.get("components"),
        "last_digest": new_data.get("last_digest"),
        "unfixed_high_critical": new_data.get("unfixed_high_critical"),
    }
    meaningful_change = (old_cmp != new_cmp) or bool(fixed_cves)

    if not meaningful_change:
        print("No version, base OS, digest, or CVE status change detected; skipping doc updates.")
        return 0

    # 1. Write versions.json
    versions_path.write_text(json.dumps(new_data, indent=2) + "\n", encoding="utf-8")

    # 2. Update README.md between <!-- versions:start --> and <!-- versions:end -->
    if readme_path.exists():
        readme = readme_path.read_text(encoding="utf-8")
        start_marker = "<!-- versions:start -->"
        end_marker = "<!-- versions:end -->"
        if start_marker in readme and end_marker in readme:
            rows = [
                "| Component | Resolved version |",
                "|---|---|",
                f"| Base OS | Debian `{debian_ver}` (`debian:trixie-slim`) |",
            ]
            for k, v in components.items():
                display_v = v[:12] if len(v) == 40 and all(c in "0123456789abcdef" for c in v.lower()) else v
                rows.append(f"| `{k}` | `{display_v}` |")
            rows.append(f"| Last verified build | `{build_date}` |")
            rows.append("| Fixable CRITICAL / HIGH CVEs | `0` (Trivy + Grype gate) |")
            if new_data.get("last_digest"):
                rows.append(f"| Published digest | `{new_data['last_digest']}` |")

            block_lines = [start_marker, "", *rows]
            safe_highlights = sanitize_notes(upstream_notes_raw, max_lines=5)
            if safe_highlights:
                block_lines.append("")
                block_lines.append("Recent upstream release highlights:")
                block_lines.append("")
                for h in safe_highlights:
                    block_lines.append(f"- {h}")
            if unfixed_list:
                block_lines.append("")
                block_lines.append(f"Currently tracked unfixed upstream findings (no fix released): {', '.join(f'`{c}`' for c in unfixed_list[:10])}.")
            block_lines.extend(["", end_marker])

            new_block = "\n".join(block_lines)
            pattern = re.compile(re.escape(start_marker) + r".*?" + re.escape(end_marker), re.DOTALL)
            readme_updated = pattern.sub(lambda _m: new_block, readme, count=1)
            readme_path.write_text(readme_updated, encoding="utf-8")

    # 3. Prepend or update dated entry in CHANGELOG.md
    if changelog_path.exists():
        cl = changelog_path.read_text(encoding="utf-8")
        heading = f"## [{upstream_ver}] - {build_date}"
        entry_lines = [heading, "", "### Changed", ""]
        comp_summary = ", ".join(
            f"{k} `{v[:12] if len(v) == 40 else v}`" for k, v in components.items()
        )
        entry_lines.append(f"- Rebuilt on Debian `{debian_ver}` (`debian:trixie-slim`) with {comp_summary}.")
        if fixed_cves:
            entry_lines.append(f"- Resolved vulnerabilities: {', '.join(f'`{c}`' for c in fixed_cves)}.")
        else:
            entry_lines.append("- Verified `0` fixable CRITICAL/HIGH vulnerabilities in Trivy and Grype.")
        if new_data.get("last_digest"):
            entry_lines.append(f"- Published digest: `{new_data['last_digest']}`.")
        safe_highlights = sanitize_notes(upstream_notes_raw, max_lines=4)
        for h in safe_highlights:
            entry_lines.append(f"- Upstream: {h}")

        new_entry = "\n".join(entry_lines) + "\n\n"
        if heading in cl:
            # Replace only if the current heading is not the initial hand-written entry
            # or append a concise update note; avoid clobbering initial release details.
            if "Initial public build" not in cl.split(heading, 1)[1].split("\n## ", 1)[0]:
                pattern = re.compile(re.escape(heading) + r".*?(?=\n## |\Z)", re.DOTALL)
                cl = pattern.sub(lambda _m: new_entry.rstrip("\n"), cl, count=1)
                changelog_path.write_text(cl, encoding="utf-8")
        else:
            m = re.search(r"^## ", cl, re.MULTILINE)
            if m:
                cl = cl[: m.start()] + new_entry + cl[m.start() :]
            else:
                cl = cl.rstrip() + "\n\n" + new_entry
            changelog_path.write_text(cl, encoding="utf-8")

    print("Documentation and versions.json updated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
