#!/usr/bin/env bash
# Public-content check: fails if deployment-specific or personal details appear
# in tracked files, and verifies LICENSE, maintainer attribution, and dual
# packaging/upstream license badges.
set -euo pipefail
ATTRIBUTION='Daniel G. Cosenza from FNX Labs'
FORBIDDEN='192\.168\.[0-9]+\.[0-9]+|(^|[^0-9.])100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|fnxlabs-|\.net\.ar|fnxusa|benjacszotk|tailscale|tailnet|\.ts\.net|homelab|home server|\bfleet\b|/opt/fnx|/home/fnx|Downloads/AI|fnxrollback|docker-tag-(check|promote)|update-all|\bpc0[0-9]\b|\b(codex|claude|antigravity|opencode|grok|gemini)\b|@gmail\.com|@duck\.com|\bART\b'
fail=0
if git grep -nIiE "$FORBIDDEN" -- . ':!.github/scripts/public-check.sh' ':!.gitignore' ':!.dockerignore'; then
  echo "::error::Forbidden deployment-specific or personal content found (see lines above)."; fail=1
fi
[ -f LICENSE ] || { echo "::error::LICENSE file is missing at repository root."; fail=1; }
grep -qF "$ATTRIBUTION" LICENSE || { echo "::error::LICENSE must name the copyright holder as \"$ATTRIBUTION\"."; fail=1; }
grep -qF "$ATTRIBUTION" README.md || { echo "::error::README.md must name the maintainer as \"$ATTRIBUTION\"."; fail=1; }
grep -qF "$ATTRIBUTION" Dockerfile || { echo "::error::Dockerfile OCI authors/vendor labels must be \"$ATTRIBUTION\"."; fail=1; }
grep -qE 'img\.shields\.io/badge/packaging-MIT' README.md || { echo "::error::README.md must include the packaging: MIT license badge."; fail=1; }
grep -qE 'img\.shields\.io/badge/upstream-[A-Za-z0-9_.+-]+' README.md || { echo "::error::README.md must include the upstream SPDX license badge."; fail=1; }
grep -qE '^## License' README.md || { echo "::error::README.md must include a License section explaining the packaging/upstream split."; fail=1; }
if [ -n "${PR_TEXT:-}" ] && printf '%s' "$PR_TEXT" | grep -nIiE "$FORBIDDEN"; then
  echo "::error::Pull request title/body contains forbidden content."; fail=1
fi
exit "$fail"
