#!/usr/bin/env bash
# Mirror identical OCI digests and keyless Cosign signatures from GHCR to
# optional secondary public container registries when their credentials are
# configured as repository secrets.
#
# Maintainer: Daniel G. Cosenza from FNX Labs
#
# Usage:
#   mirror-registries.sh --spec "<slug>|<digest>|<tag1,tag2,...>" [--spec ...]
#
# Optional environment variables (skip registry cleanly when unset):
#   QUAY_USERNAME, QUAY_TOKEN, QUAY_NAMESPACE (default: dgcosenza)
#   GITLAB_USERNAME, GITLAB_TOKEN, GITLAB_NAMESPACE (default: dgcosenza/containers)
#   CODEBERG_USERNAME, CODEBERG_TOKEN, CODEBERG_NAMESPACE (default: dgcosenza)
#   ECR_PUBLIC_ALIAS, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
set -euo pipefail

SOURCE_OWNER="${SOURCE_OWNER:-dgcosenza}"
SPECS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --spec)
      SPECS+=("$2")
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [ "${#SPECS[@]}" -eq 0 ]; then
  echo "ERROR: at least one --spec '<slug>|<digest>|<tags>' is required." >&2
  exit 2
fi

mirror_to_registry() {
  local label="$1"
  local target_prefix="$2"
  local create_ecr="${3:-false}"

  for spec in "${SPECS[@]}"; do
    IFS='|' read -r slug digest tags_csv <<< "$spec"
    if [ -z "$slug" ] || [ -z "$digest" ] || [ -z "$tags_csv" ]; then
      echo "ERROR: invalid spec: ${spec}" >&2
      exit 2
    fi

    local src_ref="ghcr.io/${SOURCE_OWNER}/${slug}@${digest}"
    local dst_repo="${target_prefix}/${slug}"

    if [ "$create_ecr" = "true" ] && command -v aws >/dev/null 2>&1; then
      aws ecr-public create-repository --region us-east-1 --repository-name "${slug}" >/dev/null 2>&1 || true
    fi

    IFS=',' read -r -a tag_arr <<< "$tags_csv"
    local first_tag="${tag_arr[0]}"

    echo "==> [${label}] Copying ${src_ref} -> ${dst_repo}:${first_tag}"
    crane copy "${src_ref}" "${dst_repo}:${first_tag}"

    local t
    for t in "${tag_arr[@]:1}"; do
      [ -n "$t" ] && crane tag "${dst_repo}@${digest}" "$t"
    done

    local mirrored_digest
    mirrored_digest="$(crane digest "${dst_repo}:${first_tag}")"
    if [ "${mirrored_digest}" != "${digest}" ]; then
      echo "ERROR: [${label}] digest mismatch for ${dst_repo}: expected ${digest}, got ${mirrored_digest}" >&2
      exit 1
    fi
    echo "==> [${label}] Verified identical digest: ${dst_repo}@${mirrored_digest}"

    if command -v cosign >/dev/null 2>&1; then
      echo "==> [${label}] Signing ${dst_repo}@${digest} with Cosign OIDC"
      cosign sign --yes "${dst_repo}@${digest}"
      # Sign each platform manifest digest when the target is an OCI index
      local plat_digests
      plat_digests="$(crane manifest "${src_ref}" | jq -r '.manifests[]? | select((.platform.os // "") != "" and (.platform.os // "") != "unknown") | .digest' || true)"
      local pd
      for pd in $plat_digests; do
        [ -n "$pd" ] && cosign sign --yes "${dst_repo}@${pd}"
      done
    fi
  done
}

# 1. Red Hat Quay.io
if [ -n "${QUAY_USERNAME:-}" ] && [ -n "${QUAY_TOKEN:-}" ]; then
  QUAY_NS="${QUAY_NAMESPACE:-${SOURCE_OWNER}}"
  printf '%s' "${QUAY_TOKEN}" | crane auth login quay.io -u "${QUAY_USERNAME}" --password-stdin
  mirror_to_registry "Quay.io" "quay.io/${QUAY_NS}" "false"
else
  echo "Skipping Quay.io mirror (QUAY_USERNAME/QUAY_TOKEN not configured)."
fi

# 2. GitLab Container Registry
if [ -n "${GITLAB_USERNAME:-}" ] && [ -n "${GITLAB_TOKEN:-}" ]; then
  GITLAB_NS="${GITLAB_NAMESPACE:-${SOURCE_OWNER}/containers}"
  printf '%s' "${GITLAB_TOKEN}" | crane auth login registry.gitlab.com -u "${GITLAB_USERNAME}" --password-stdin
  mirror_to_registry "GitLab" "registry.gitlab.com/${GITLAB_NS}" "false"
else
  echo "Skipping GitLab Container Registry mirror (GITLAB_USERNAME/GITLAB_TOKEN not configured)."
fi

# 3. Codeberg Container Registry
if [ -n "${CODEBERG_USERNAME:-}" ] && [ -n "${CODEBERG_TOKEN:-}" ]; then
  CODEBERG_NS="${CODEBERG_NAMESPACE:-${SOURCE_OWNER}}"
  printf '%s' "${CODEBERG_TOKEN}" | crane auth login codeberg.org -u "${CODEBERG_USERNAME}" --password-stdin
  mirror_to_registry "Codeberg" "codeberg.org/${CODEBERG_NS}" "false"
else
  echo "Skipping Codeberg Container Registry mirror (CODEBERG_USERNAME/CODEBERG_TOKEN not configured)."
fi

# 4. Amazon ECR Public
if [ -n "${ECR_PUBLIC_ALIAS:-}" ] && [ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ]; then
  aws ecr-public get-login-password --region us-east-1 | crane auth login public.ecr.aws -u AWS --password-stdin
  mirror_to_registry "Amazon ECR Public" "public.ecr.aws/${ECR_PUBLIC_ALIAS}" "true"
else
  echo "Skipping Amazon ECR Public mirror (ECR_PUBLIC_ALIAS/AWS credentials not configured)."
fi
