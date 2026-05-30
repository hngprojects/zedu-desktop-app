#!/usr/bin/env bash
# forbidden-pattern-scan.sh
# Scans the codebase for hardcoded secrets, API keys, and other forbidden patterns.
# Usage: bash scripts/forbidden-pattern-scan.sh <directory>

set -euo pipefail

SCAN_DIR="${1:-.}"
EXIT_CODE=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Running forbidden pattern scan on: $SCAN_DIR"
echo "=============================================="

# ── Forbidden patterns ────────────────────────────────────────────────────────
declare -A PATTERNS
PATTERNS["Hardcoded IP address"]='(http|https)://[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
PATTERNS["AWS Access Key"]='AKIA[0-9A-Z]{16}'
PATTERNS["AWS Secret Key"]='(?i)aws.{0,20}secret.{0,20}[=:].{0,40}[A-Za-z0-9/+=]{40}'
PATTERNS["Generic API Key"]='(?i)(api_key|apikey|api-key)\s*[:=]\s*["\x27]?[A-Za-z0-9_\-]{20,}["\x27]?'
PATTERNS["Generic Secret"]='(?i)(secret|password|passwd|pwd)\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]'
PATTERNS["Private Key Block"]='-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
PATTERNS["Google API Key"]='AIza[0-9A-Za-z\-_]{35}'
PATTERNS["Slack Token"]='xox[baprs]-[0-9a-zA-Z\-]+'
PATTERNS["GitHub Token"]='(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}'
PATTERNS["Bearer Token hardcoded"]='(?i)bearer\s+[A-Za-z0-9\-._~+/]+=*'
PATTERNS["TODO with credential hint"]='(?i)TODO.*(key|secret|token|password)'

# ── File extensions to scan ───────────────────────────────────────────────────
INCLUDE_EXTS="dart,yaml,yml,json,sh,env,txt,md,gradle,xml,properties"

# ── Paths to exclude ──────────────────────────────────────────────────────────
EXCLUDE_DIRS=".git|build|.dart_tool|.pub-cache|node_modules|.gradle|ios/Pods"

echo ""

FOUND_COUNT=0

for LABEL in "${!PATTERNS[@]}"; do
  PATTERN="${PATTERNS[$LABEL]}"

  # Use grep with Perl-compatible regex, exclude binary files and ignored dirs
  MATCHES=$(grep -rPn --include="*.{$INCLUDE_EXTS}" \
    --exclude-dir={.git,build,.dart_tool,.pub-cache,node_modules,.gradle} \
    "$PATTERN" "$SCAN_DIR" 2>/dev/null || true)

  if [[ -n "$MATCHES" ]]; then
    echo -e "${RED}❌ FOUND: ${LABEL}${NC}"
    echo "$MATCHES" | while IFS= read -r line; do
      echo -e "   ${YELLOW}→ $line${NC}"
    done
    echo ""
    FOUND_COUNT=$((FOUND_COUNT + 1))
    EXIT_CODE=1
  fi
done

echo "=============================================="
if [[ $EXIT_CODE -eq 0 ]]; then
  echo -e "${GREEN}✅ No forbidden patterns found. All clear!${NC}"
else
  echo -e "${RED}❌ Forbidden patterns detected in $FOUND_COUNT category(ies). Please review and remove them before merging.${NC}"
fi
echo "=============================================="

exit $EXIT_CODE
