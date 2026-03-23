#!/usr/bin/env bash
set -euo pipefail

# Pre-BaseSpace access check
# Verifies access to all unique projects in matched_database.csv before running
# the pipeline. Run this after find_samples.sh.
#
# Usage: bash check_bs_access.sh [matched_database.csv]
# Default input: tmp/matched_database.csv (col 3 = projectID)

OB_DIR="${OB_DIR:-$(cd "$(dirname "$0")" && pwd)}"
BS="${BS:-$HOME/tools/basespace}"
INPUT="${1:-$OB_DIR/tmp/matched_database.csv}"

[[ -f "$INPUT"  ]] || { echo "ERROR: input not found: $INPUT" >&2; exit 1; }
[[ -x "$BS"     ]] || { echo "ERROR: basespace CLI not found: $BS" >&2; exit 1; }

# Extract unique project IDs (strip _AR suffix)
mapfile -t PROJECTS < <(
    awk -F',' 'NR>1 && $3!="" { proj=$3; sub(/_AR$/, "", proj); print proj }' "$INPUT" \
    | sort -u
)

total=${#PROJECTS[@]}
ok=0; fail=0
failed=()

echo "Checking access to $total project(s) via BaseSpace..."
echo

for proj in "${PROJECTS[@]}"; do
    result=$("$BS" list projects --filter-field Name --filter-term "$proj" 2>/dev/null || true)
    if echo "$result" | grep -q "$proj"; then
        echo "  OK          $proj"
        (( ok++ )) || true
    else
        echo "  NO ACCESS   $proj"
        failed+=("$proj")
        (( fail++ )) || true
    fi
done

echo
echo "########################################"
echo "accessible:   $ok / $total"
[[ $fail -eq 0 ]] && echo "All projects accessible — ready to run." \
                  || echo "Need access to $fail project(s):"
for p in "${failed[@]}"; do echo "  $p"; done
echo "########################################"

[[ $fail -eq 0 ]]
