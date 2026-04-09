#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AR_PASS_DIR="${AR_PASS_DIR:-$SCRIPT_DIR}"
ACTIVE_TSV="$AR_PASS_DIR/ar_pass.tsv"
ARCHIVE_DIR="$AR_PASS_DIR/archive"
MODE="copy"
STAMP="${ARCHIVE_DATE:-$(date +%F)}"

usage() {
  cat <<EOF >&2
Usage: $0 [--copy|--move] [--date YYYY-MM-DD] <new_ar_pass.tsv>

Installs a new active ar_pass table at:
  $ACTIVE_TSV

Behavior:
  - archives the current active table to $ARCHIVE_DIR
  - validates the incoming TSV header
  - copies the new file by default

Options:
  --copy             Copy the source file into place (default)
  --move             Move the source file into place
  --date YYYY-MM-DD  Use this archive date instead of today
EOF
  exit 1
}

validate_table() {
  local table_path="$1"

  awk -F'\t' '
NR==1 {
  for (i=1; i<=NF; i++) header[$i]=1
  need[1]="entity:ar_pass_id"
  need[2]="basespace_collection_id"
  need[3]="sequence_classification"
  for (i=1; i<=3; i++) {
    if (!(need[i] in header)) {
      printf("ERROR: missing required ar_pass header: %s\n", need[i]) > "/dev/stderr"
      exit 2
    }
  }
  exit 0
}
END {
  if (NR == 0) {
    print "ERROR: ar_pass table is empty" > "/dev/stderr"
    exit 3
  }
}
' "$table_path"
}

archive_active_table() {
  local archive_path base_path suffix

  [[ -f "$ACTIVE_TSV" ]] || return 0

  mkdir -p "$ARCHIVE_DIR"
  base_path="$ARCHIVE_DIR/ar_pass_${STAMP}"
  archive_path="${base_path}.tsv"
  suffix=1
  while [[ -e "$archive_path" ]]; do
    archive_path="${base_path}_${suffix}.tsv"
    suffix=$((suffix + 1))
  done

  mv "$ACTIVE_TSV" "$archive_path"
  echo "Archived existing active table to: $archive_path"
}

src_path=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      MODE="copy"
      shift
      ;;
    --move)
      MODE="move"
      shift
      ;;
    --date)
      [[ $# -ge 2 ]] || usage
      STAMP="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    -* )
      echo "ERROR: unknown option: $1" >&2
      usage
      ;;
    * )
      [[ -z "$src_path" ]] || usage
      src_path="$1"
      shift
      ;;
  esac
done

[[ -n "$src_path" ]] || usage
[[ -f "$src_path" ]] || { echo "ERROR: file not found: $src_path" >&2; exit 1; }

src_abs="$(cd "$(dirname "$src_path")" && pwd)/$(basename "$src_path")"
active_abs="$(cd "$AR_PASS_DIR" && pwd)/ar_pass.tsv"
[[ "$src_abs" != "$active_abs" ]] || { echo "ERROR: source is already the active ar_pass table" >&2; exit 1; }

validate_table "$src_abs"
archive_active_table

mkdir -p "$AR_PASS_DIR"
if [[ "$MODE" == "move" ]]; then
  mv "$src_abs" "$ACTIVE_TSV"
else
  cp "$src_abs" "$ACTIVE_TSV"
fi

echo "Installed active ar_pass table: $ACTIVE_TSV"
echo "Install mode: $MODE"
