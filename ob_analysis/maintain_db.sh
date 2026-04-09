#!/usr/bin/env bash
set -euo pipefail

# Default paths
DB="${DB:-$HOME/workflows/ODHL_AR/assets/databases/IDdbs/db_master.csv}"
ARPASS="${ARPASS:-$HOME/workflows/ODHL_AR/assets/databases/ar_pass/ar_pass.tsv}"

# Accept optional positional args to override defaults
[[ $# -ge 1 ]] && DB="$1"
[[ $# -ge 2 ]] && ARPASS="$2"

[[ -f "$DB" ]]     || { echo "ERROR: db_master not found: $DB" >&2; exit 1; }
[[ -f "$ARPASS" ]] || { echo "ERROR: ar_pass not found: $ARPASS" >&2; exit 1; }

# Archive the existing db_master before overwriting
ARCHIVE_DIR="$(dirname "$DB")/archive"
mkdir -p "$ARCHIVE_DIR"
ARCHIVE_DATE="$(date +%Y-%m-%d)"
ARCHIVE_DEST="$ARCHIVE_DIR/db_master_${ARCHIVE_DATE}.csv"
cp "$DB" "$ARCHIVE_DEST"
echo "Archived: $ARCHIVE_DEST" >&2

AWK_PROG="$(mktemp)"
trap 'rm -f "$AWK_PROG"' EXIT

# Step 1 awk program: merge ar_pass entries into db_master
cat > "$AWK_PROG" <<'AWK'
function ltrim(s){ sub(/^[[:space:]]+/, "", s); return s }
function rtrim(s){ sub(/[[:space:]]+$/, "", s); return s }
function trim(s){ return rtrim(ltrim(s)) }
function strip_bom(s){ sub(/^\xEF\xBB\xBF/,"",s); return s }  # remove UTF-8 BOM if present
function up(s){ return toupper(s) }
function normdate(s){ s=trim(s); gsub(/[^0-9]/,"",s); return s }  # -> YYYYMMDD if already yyyy-mm-dd
function compkey(ohio, proj){ return up(ohio) "-" up(proj) }

# Normalize a header token: trim + strip BOM
function norm_header(h){ h=strip_bom(trim(h)); return h }

# ------- PASS 1: read db_master.csv --------
FNR==1 && ARGIND==1 {
  FS=","; OFS=","
  header=$0
  n=split($0, cols, FS)
  for(i=1;i<=n;i++){
    name = norm_header(cols[i])
    db_idx[name]=i
  }
  need="PROJECT_ID,OHIO_ID,WGSID,SRRID,SAMID,DATE_ASSIGNED"
  m=split(need, req, /,/)
  for(i=1;i<=m;i++){
    if(!(req[i] in db_idx)){
      printf("ERROR: db_master missing column: %s\n", req[i]) > "/dev/stderr"; exit 2
    }
  }
  next
}

ARGIND==1 && FNR>1 {
  # skip blank lines
  if (trim($0)=="") next

  proj = trim($(db_idx["PROJECT_ID"]))
  ohio = trim($(db_idx["OHIO_ID"]))
  wgs  = trim($(db_idx["WGSID"]))
  srr  = trim($(db_idx["SRRID"]))
  sam  = trim($(db_idx["SAMID"]))
  dat  = trim($(db_idx["DATE_ASSIGNED"]))

  if (proj=="" || ohio=="") next

  k = compkey(ohio, proj)
  if (!(k in seen)){
    order[++N]=k; seen[k]=1
    PROJ[k]=proj; OHIO[k]=ohio; WGS[k]=wgs; SRR[k]=srr; SAM[k]=sam; DAT[k]=dat
  }
  next
}

# ------- PASS 2: read ar_pass.tsv --------
FNR==1 && ARGIND==2 {
  FS="\t"  # TSV
  n=split($0, cols, FS)
  for(i=1;i<=n;i++){
    name = norm_header(cols[i])
    ap_idx[name]=i
  }

  if (!("entity:ar_pass_id" in ap_idx) || !("basespace_collection_id" in ap_idx)) {
    print "ERROR: ar_pass.tsv must include headers: entity:ar_pass_id and basespace_collection_id" > "/dev/stderr"
    exit 3
  }

  col_wgs  = (("wgs_id"                     in ap_idx) ? ap_idx["wgs_id"]                     : 0)
  col_srr  = (("srr_number"                 in ap_idx) ? ap_idx["srr_number"]                 : 0)
  col_date = (("wgs_date_put_on_sequencer"  in ap_idx) ? ap_idx["wgs_date_put_on_sequencer"]  : 0)
  next
}

ARGIND==2 && FNR>1 {
  if (trim($0)=="") next

  ent  = trim($(ap_idx["entity:ar_pass_id"]))
  proj = trim($(ap_idx["basespace_collection_id"]))
  if (ent=="" || proj=="") next

  wgs  = (col_wgs  ? trim($(col_wgs))  : "")
  srr  = (col_srr  ? trim($(col_srr))  : "")
  dat  = (col_date ? normdate($(col_date)) : "")

  k = compkey(ent, proj)
  if (!(k in seen)){
    order[++N]=k; seen[k]=1
    PROJ[k]=proj; OHIO[k]=ent; WGS[k]=wgs; SRR[k]=srr; SAM[k]=""; DAT[k]=dat
  }
  next
}

END{
  print "PROJECT_ID,OHIO_ID,WGSID,SRRID,SAMID,DATE_ASSIGNED"
  for(i=1;i<=N;i++){
    k=order[i]
    if (trim(PROJ[k])=="" || trim(OHIO[k])=="") continue
    print PROJ[k], OHIO[k], WGS[k], SRR[k], SAM[k], DAT[k]
  }
}
AWK

# Step 1: merge ar_pass entries
# Step 2: deduplicate — keep complete rows (SRRID + SAMID filled); fall back to first partial
# Step 3: strip run suffix from OHIO_ID (everything after first "-")
# Write result directly to db_master (in-place update)
TMP="$(mktemp --tmpdir="$(dirname "$DB")" db_master.XXXXXX.csv)"
trap 'rm -f "$TMP" "$AWK_PROG"' EXIT

awk -f "$AWK_PROG" "$DB" "$ARPASS" \
  | awk -F',' -v OFS=',' '
NR==1 { print; next }
{
  key = $1 FS $2 FS $3
  has_srr = ($4 != "" && $4 != "NA")
  has_sam = ($5 != "" && $5 != "NA")
  if (has_srr && has_sam) {
    complete[key] = $0
  } else if (!(key in partial)) {
    partial[key] = $0
  }
}
END {
  for (k in complete) print complete[k]
  for (k in partial)  if (!(k in complete)) print partial[k]
}' \
  | awk -F',' -v OFS=',' '
NR==1 { print; next }
{
  split($2, parts, "-")
  $2 = parts[1]
  print
}' > "$TMP"

mv "$TMP" "$DB"
echo "Updated:  $DB" >&2
