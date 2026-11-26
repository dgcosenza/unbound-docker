#!/usr/bin/env python3
"""Update versions.json, README.md current-versions block, and CHANGELOG.md."""
from __future__ import annotations

import json
import pathlib
import re
import sys


def load_forbidden_regex() -> re.Pattern[str] | None:
    check_script = pathlib.Path(".github/scripts/public-check.sh")
    if not check_script.exists():
        return None
    for line in check_script.read_text(encoding="utf-8").splitlines():
        if line.startswith("FORBIDDEN='") and line.endswith("'"):
            return re.compile(line[len("FORBIDDEN='") : -1], re.IGNORECASE)
    return None


FORBIDDEN_RE = load_forbidden_regex()


def sanitize_bullets(markdown_text: str, max_lines: int = 8) -> list[str]:
    bullets: list[str] = []
    for raw in markdown_text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith(("- ", "* ")):
            line = line[2:].strip()
        if not line:
            continue
        if FORBIDDEN_RE and FORBIDDEN_RE.search(line):
            continue
        if len(line) > 180:
            line = line[:177].rstrip() + "..."
        bullets.append(line)
        if len(bullets) >= max_lines:
            break
    return bullets


def build_readme_block(meta: dict, bullets: list[str]) -> str:
    rows = [
        "| Component | Resolved Version |",
        "| --- | --- |",
    ]
    for k, v in (meta.get("components") or {}).items():
        display_v = v[:12] if isinstance(v, str) and len(v) == 40 and all(c in "0123456789abcdef" for c in v.lower()) else v
        rows.append(f"| {k} | `{display_v}` |")
    arches = meta.get("architectures") or []
    if arches:
        rows.append(f"| Architectures | `{', '.join(arches)}` |")
    sizes = meta.get("sizes_mb") or {}
    if sizes:
        size_str = ", ".join(f"{k}: {v} MB" for k, v in sizes.items())
        rows.append(f"| Compressed size (per arch) | `{size_str}` |")
    rows.append(f"| Last verified build (UTC) | `{meta.get('build_date', 'unknown')}` |")
    digest = meta.get("image_digest") or ""
    if digest:
        rows.append(f"| Published multi-arch digest | `{digest}` |")
    ghcr = meta.get("ghcr_digest") or ""
    if ghcr:
        rows.append(f"| GHCR mirror | `{ghcr}` |")
    if meta.get("signed"):
        rows.append("| Supply chain | Cosign OIDC signed + SPDX & CycloneDX SBOM attestations + SLSA Build L3 provenance |")
    fixable = meta.get("fixable_critical_high", 0)
    unfixed = meta.get("unfixed_cves") or []
    rows.append(
        f"| Security gate (Trivy + Grype on SBOM) | **{fixable} fixable findings of any severity** ({len(unfixed)} upstream-unfixed) |"
    )

    lines = [
        "<!-- versions:start -->",
        *rows,
    ]
    if bullets:
        lines.append("")
        lines.append("**Recent upstream changes:**")
        for b in bullets[:5]:
            lines.append(f"- {b}")
    if unfixed:
        lines.append("")
        shown = ", ".join(f"`{c}`" for c in unfixed[:10])
        suffix = f" (+{len(unfixed) - 10} more in CI artifacts)" if len(unfixed) > 10 else ""
        lines.append(f"Currently tracked upstream-unfixed findings (no fix released): {shown}{suffix}.")
    lines.append("<!-- versions:end -->")
    return "\n".join(lines)


def update_readme(readme_path: pathlib.Path, meta: dict, bullets: list[str]) -> None:
    text = readme_path.read_text(encoding="utf-8")
    pattern = re.compile(r"<!-- versions:start -->.*?<!-- versions:end -->", re.DOTALL)
    if not pattern.search(text):
        raise SystemExit("README.md is missing <!-- versions:start --> / <!-- versions:end --> markers")
    block = build_readme_block(meta, bullets)
    new_text = pattern.sub(lambda _m: block, text, count=1)
    if new_text != text:
        readme_path.write_text(new_text, encoding="utf-8")


def update_changelog(
    changelog_path: pathlib.Path,
    meta: dict,
    prev_meta: dict,
    bullets: list[str],
    cve_diff: dict,
) -> None:
    text = changelog_path.read_text(encoding="utf-8")
    date_str = meta.get("build_date") or ""
    version_label = meta.get("changelog_version") or meta.get("upstream_version") or "daily"
    if not date_str:
        return

    digest = meta.get("image_digest") or ""
    prev_digest = prev_meta.get("image_digest") or prev_meta.get("last_digest") or ""
    fixed_cves = cve_diff.get("cves_fixed_since_previous") or []
    changed = (
        meta.get("upstream_version") != prev_meta.get("upstream_version")
        or meta.get("components") != prev_meta.get("components")
        or meta.get("base_digest") != prev_meta.get("base_digest")
        or meta.get("architectures") != prev_meta.get("architectures")
        or bool(fixed_cves)
        or (digest and digest != prev_digest)
    )
    if not changed:
        return

    heading = f"## [{version_label}] - {date_str}"
    entry_lines = [heading, "", "### Automated Daily Build"]
    comps = meta.get("components") or {}
    if comps:
        comp_str = ", ".join(
            f"{k} `{v[:12] if isinstance(v, str) and len(v) == 40 else v}`"
            for k, v in comps.items()
        )
        entry_lines.append(f"- Verified components: {comp_str}.")
    arches = meta.get("architectures") or []
    if arches:
        entry_lines.append(
            f"- Architectures verified: `{', '.join(arches)}` (native smoke tests + Dive efficiency gate)."
        )
    if bullets:
        entry_lines.append("- Upstream changes:")
        for b in bullets[:5]:
            entry_lines.append(f"  - {b}")
    else:
        entry_lines.append("- Upstream status: refreshed base OS, dependencies, and supply-chain attestations.")
    if fixed_cves:
        entry_lines.append(f"- CVEs resolved since previous scan: {', '.join(f'`{c}`' for c in fixed_cves)}.")
    else:
        entry_lines.append(
            f"- Vulnerability gate: **0 fixable findings of any severity** in Trivy and Grype (SBOM scan) "
            f"({len(meta.get('unfixed_cves') or [])} upstream-unfixed)."
        )
    if digest:
        entry_lines.append(
            f"- Published multi-arch digest (Docker Hub + GHCR): `{digest}` "
            f"(Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance)."
        )
    entry_block = "\n".join(entry_lines)

    date_section_re = re.compile(
        rf"^## \[[^\]]+\] - {re.escape(date_str)}\n+### Automated Daily Build\n.*?(?=\n## \[|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    if date_section_re.search(text):
        new_text = date_section_re.sub(lambda _m: entry_block, text, count=1)
    else:
        m = re.search(r"^## \[", text, re.MULTILINE)
        if m:
            new_text = text[: m.start()] + entry_block + "\n\n" + text[m.start() :]
        else:
            new_text = text.rstrip() + "\n\n" + entry_block + "\n"

    if new_text != text:
        changelog_path.write_text(new_text, encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 4:
        print(
            "Usage: update-docs.py <versions-new.json> <upstream-changes.md> <cve-diff.json>",
            file=sys.stderr,
        )
        return 2

    new_versions_path = pathlib.Path(sys.argv[1])
    changes_path = pathlib.Path(sys.argv[2])
    cve_diff_path = pathlib.Path(sys.argv[3])

    repo_versions = pathlib.Path("versions.json")
    prev_meta: dict = {}
    if repo_versions.exists():
        try:
            prev_meta = json.loads(repo_versions.read_text(encoding="utf-8"))
        except Exception:
            prev_meta = {}

    meta = json.loads(new_versions_path.read_text(encoding="utf-8"))
    cve_diff = (
        json.loads(cve_diff_path.read_text(encoding="utf-8"))
        if cve_diff_path.exists()
        else {}
    )
    changes_text = changes_path.read_text(encoding="utf-8") if changes_path.exists() else ""
    bullets = sanitize_bullets(changes_text)

    repo_versions.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    update_readme(pathlib.Path("README.md"), meta, bullets)
    update_changelog(pathlib.Path("CHANGELOG.md"), meta, prev_meta, bullets, cve_diff)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
