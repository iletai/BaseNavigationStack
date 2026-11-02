#!/usr/bin/env bash
#
# scripts/sync-wiki.sh
# Push docs/wiki/ to https://github.com/iletai/BaseNavigationStack.wiki.git
#
# Requires:
# 1. Wiki enabled on GitHub repo settings (create at least one page first so .wiki.git exists).
# 2. Push rights (SSH key or gh auth).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIKI_DIR="${REPO_DIR}/docs/wiki"
REMOTE_URL="${WIKI_REMOTE:-https://github.com/iletai/BaseNavigationStack.wiki.git}"
TMP_DIR="$(mktemp -d -t bnswiki.XXXXXX)"

trap 'rm -rf "${TMP_DIR}"' EXIT

if [ ! -d "${WIKI_DIR}" ]; then
    echo "Error: ${WIKI_DIR} not found" >&2
    exit 1
fi

echo "Cloning wiki repo into temp dir..."
if ! git clone "${REMOTE_URL}" "${TMP_DIR}" 2>/dev/null; then
    echo "Wiki repo not found remotely. Initializing fresh repo..."
    git -C "${TMP_DIR}" init -b master
    git -C "${TMP_DIR}" remote add origin "${REMOTE_URL}"
fi

echo "Syncing wiki files..."
# Clear tracked files, replace with fresh contents
find "${TMP_DIR}" -maxdepth 1 -not -name '.git' -not -name '.' -exec rm -rf {} +
cp -R "${WIKI_DIR}/"* "${TMP_DIR}/"

cd "${TMP_DIR}"
git add -A

if git diff --cached --quiet; then
    echo "No wiki changes to commit."
    exit 0
fi

COMMIT_MSG="docs(wiki): sync wiki pages $(date -u '+%Y-%m-%d %H:%M:%SZ')"
git commit -m "${COMMIT_MSG}"

echo "Pushing to ${REMOTE_URL}..."
git push origin HEAD

echo "Wiki sync completed successfully."
