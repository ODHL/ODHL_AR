#!/usr/bin/env bash
set -euo pipefail

OB_DIR="${OB_DIR:-$(cd "$(dirname "$0")" && pwd)}"
WF_DIR="$(cd "$OB_DIR/.." && pwd)"

SAMPLES_FILE="${SAMPLES_FILE:-$OB_DIR/samples.csv}"
AR_PASS_TSV="${AR_PASS_TSV:-$OB_DIR/ar_pass.tsv}"
EXTRA_TSV="${EXTRA_TSV:-$OB_DIR/extra_meta.tsv}"
DB_MASTER_CSV="${DB_MASTER_CSV:-$WF_DIR/assets/databases/IDdbs/db_master.csv}"
TARGET_TOTAL="${TARGET_TOTAL:-15}"
PROJECT="${1:-${PROJECT:-OB$(date +%y%m%d)}}"

TMP_DIR="$OB_DIR/tmp"
OUTDIR="$HOME/output/$PROJECT/input"
mkdir -p "$TMP_DIR" "$OUTDIR"

SOURCE_IDS="$TMP_DIR/source_ids.txt"
SOURCE_RESOLVED="$TMP_DIR/source_resolved.csv"
SOURCE_MISSING="$TMP_DIR/source_missing.txt"
REF_CANDIDATES="$TMP_DIR/ref_candidates.csv"
REF_SELECTED="$TMP_DIR/ref_selected.csv"
SELECTED_ALL="$TMP_DIR/selected_samples.csv"
SELECTED_META="$TMP_DIR/selected_for_metadata.csv"
MATCHED_DB="$TMP_DIR/matched_database.csv"
REF_SAMPLES="$OUTDIR/ref_samples.csv"
METADATA_OUT="$TMP_DIR/metadata_for_script.csv"
MISSING_META="$TMP_DIR/missing_samples.txt"

[[ -f "$SAMPLES_FILE" ]] || { echo "ERROR: samples file not found: $SAMPLES_FILE" >&2; exit 1; }
[[ -f "$AR_PASS_TSV" ]] || { echo "ERROR: ar_pass TSV not found: $AR_PASS_TSV" >&2; exit 1; }

awk '
function up(s){ return toupper(s) }
function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
function trim(s){ return ltrim(rtrim(s)) }
function is_id(s){ s=up(trim(s)); return (s ~ /^[0-9]{2}AR[0-9]+([_-].*)?$/) }
function canon_id(s){ s=up(trim(s)); sub(/[_-].*/, "", s); return s }

BEGIN{ FS="[,\t]" }
{
  line=$0
  gsub(/\r$/, "", line)
  line=trim(line)
  if (line=="" || substr(line,1,1)=="#") next

  n=split(line, a, FS)
  sid=""
  for (i=1; i<=n; i++) {
    if (is_id(a[i])) {
      sid=canon_id(a[i])
      break
    }
  }
  if (sid=="" || sid=="SAMPLEID") next
  if (!(sid in seen)) {
    seen[sid]=1
    print sid
  }
}
' "$SAMPLES_FILE" > "$SOURCE_IDS"

src_count=$(wc -l < "$SOURCE_IDS" | tr -d ' ')
if [[ "$src_count" -eq 0 ]]; then
  echo "ERROR: no sample IDs found in $SAMPLES_FILE" >&2
  exit 1
fi

awk -v IDS="$SOURCE_IDS" -v OUT="$SOURCE_RESOLVED" -v MISS="$SOURCE_MISSING" '
function up(s){ return toupper(s) }
function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
function trim(s){ return ltrim(rtrim(s)) }
function canon_id(s){ s=up(trim(s)); sub(/[_-].*/, "", s); return s }
function first_genus(species, a, n){
  species=trim(species)
  n=split(species, a, /[[:space:]]+/)
  return (n>=1 ? a[1] : species)
}
function extract_species(sc, m){
  sc=trim(sc)
  if (match(sc, /[A-Z][a-z]+ [a-z][A-Za-z.-]+/, m)) return m[0]
  return ""
}

BEGIN{
  FS="\t"
  while ((getline line < IDS) > 0) {
    line=trim(line)
    if (line!="") want[line]=1
  }
  close(IDS)
  print "sampleID,species,projectID,species_full" > OUT
  close(MISS)
}

NR==1 {
  for (i=1; i<=NF; i++) h[$i]=i
  if (!("entity:ar_pass_id" in h) || !("basespace_collection_id" in h) || !("sequence_classification" in h)) {
    print "ERROR: ar_pass.tsv missing required headers (entity:ar_pass_id, basespace_collection_id, sequence_classification)" > "/dev/stderr"
    exit 2
  }
  next
}

{
  sid=canon_id($(h["entity:ar_pass_id"]))
  if (!(sid in want)) next

  proj=trim($(h["basespace_collection_id"]))
  sc=trim($(h["sequence_classification"]))
  full=extract_species(sc)
  genus=first_genus(full)

  if (!(sid in found)) {
    print sid "," genus "," proj "," full >> OUT
    found[sid]=1
  }
}

END{
  for (sid in want) {
    if (!(sid in found)) print sid >> MISS
  }
}
' "$AR_PASS_TSV"

if [[ -s "$SOURCE_MISSING" ]]; then
  echo "ERROR: source sample(s) missing from ar_pass.tsv:" >&2
  cat "$SOURCE_MISSING" >&2
  echo "Add missing rows to ar_pass.tsv before running outbreak prep." >&2
  exit 1
fi

outbreak_species=$(awk -F',' 'NR>1 && $2!="" {print $2}' "$SOURCE_RESOLVED" | sort -u)
species_count=$(echo "$outbreak_species" | sed '/^$/d' | wc -l | tr -d ' ')
if [[ "$species_count" -ne 1 ]]; then
  echo "ERROR: source samples resolve to multiple or missing species:" >&2
  awk -F',' 'NR>1 {print "  " $1 " -> " $2}' "$SOURCE_RESOLVED" >&2
  exit 1
fi
outbreak_species=$(echo "$outbreak_species" | head -n 1)

refs_needed=$(( TARGET_TOTAL - src_count ))
if (( refs_needed < 0 )); then refs_needed=0; fi

awk -v IDS="$SOURCE_IDS" -v OUT="$REF_CANDIDATES" -v TARGET_SPECIES="$outbreak_species" '
function up(s){ return toupper(s) }
function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
function trim(s){ return ltrim(rtrim(s)) }
function canon_id(s){ s=up(trim(s)); sub(/[_-].*/, "", s); return s }
function first_genus(species, a, n){
  species=trim(species)
  n=split(species, a, /[[:space:]]+/)
  return (n>=1 ? a[1] : species)
}
function extract_species(sc, m){
  sc=trim(sc)
  if (match(sc, /[A-Z][a-z]+ [a-z][A-Za-z.-]+/, m)) return m[0]
  return ""
}

BEGIN{
  FS="\t"
  while ((getline line < IDS) > 0) {
    line=trim(line)
    if (line!="") source[line]=1
  }
  close(IDS)
  print "sampleID,species,projectID,species_full" > OUT
}

NR==1 {
  for (i=1; i<=NF; i++) h[$i]=i
  next
}

{
  sid=canon_id($(h["entity:ar_pass_id"]))
  if (sid=="" || (sid in source) || (sid in seen)) next

  sc=trim($(h["sequence_classification"]))
  full=extract_species(sc)
  genus=first_genus(full)
  if (genus != TARGET_SPECIES) next

  proj=trim($(h["basespace_collection_id"]))
  if (proj=="") next

  print sid "," genus "," proj "," full >> OUT
  seen[sid]=1
}
' "$AR_PASS_TSV"

echo "sampleID,species,projectID,species_full" > "$REF_SELECTED"
if (( refs_needed > 0 )); then
  available_refs=$(( $(wc -l < "$REF_CANDIDATES") - 1 ))
  if (( available_refs > 0 )); then
    pick_count=$refs_needed
    if (( available_refs < pick_count )); then
      pick_count=$available_refs
      echo "WARN: only $available_refs reference candidates found for species $outbreak_species" >&2
    fi
    tail -n +2 "$REF_CANDIDATES" | shuf -n "$pick_count" >> "$REF_SELECTED"
  fi
fi

{
  echo "sampleID,type,species,projectID,species_full"
  awk -F',' 'NR>1 {print $1 ",source," $2 "," $3 "," $4}' "$SOURCE_RESOLVED"
  awk -F',' 'NR>1 {print $1 ",ref," $2 "," $3 "," $4}' "$REF_SELECTED"
} > "$SELECTED_ALL"

awk -F',' 'BEGIN{print "sampleID,species,projectID"} NR>1 {print $1 "," $3 "," $4}' "$SELECTED_ALL" > "$MATCHED_DB"
awk -F',' 'BEGIN{print "sampleID,species"} NR>1 {print $1 "," $3}' "$SELECTED_ALL" > "$SELECTED_META"
awk -F',' 'NR>1 && $2=="ref" {print $1}' "$SELECTED_ALL" > "$REF_SAMPLES"

bash "$OB_DIR/check_bs_access.sh" "$MATCHED_DB"

bash "$OB_DIR/create_metadata.sh" \
  -s "$SELECTED_META" \
  -m "$AR_PASS_TSV" \
  -e "$EXTRA_TSV" \
  -d "$DB_MASTER_CSV" \
  -o "$METADATA_OUT" \
  -x "$MISSING_META"

echo "sample,results" > "$OUTDIR/labResults.csv"
awk -F',' -v species="$outbreak_species" 'NR>1 && $1!="" && $3!="" {
  proj=$3; sub(/_AR$/, "", proj)
  print $1 "-" proj "," species
}' "$MATCHED_DB" >> "$OUTDIR/labResults.csv"

echo "sample,fastq_1,fastq_2" > "$OUTDIR/samplesheet.csv"
awk -F',' 'NR>1 && $1!="" && $3!="" {
  proj=$3; sub(/_AR$/, "", proj)
  name=$1 "-" proj
  print name "," name ".R1.fastq.gz," name ".R2.fastq.gz"
}' "$MATCHED_DB" >> "$OUTDIR/samplesheet.csv"

cp "$METADATA_OUT" "$OUTDIR/${PROJECT}_metadata.csv"

cat > "$OUTDIR/run_arANALYZER.sh" <<EOF
bash "$WF_DIR/run_workflow.sh" \\
  -i $PROJECT \\
  -e arANALYSIS \\
  -n "-profile docker --max_memory 7.GB --max_cpus 4 --runBASESPACE TRUE --input \$HOME/output/$PROJECT/input/samplesheet.csv" \\
  -l \$HOME/output/$PROJECT/input/labResults.csv
EOF

cat > "$OUTDIR/run_arFORMATTER.sh" <<EOF
inputDIR="\$HOME/output/$PROJECT/input/"
metadataPATH="\$inputDIR/${PROJECT}_metadata.csv"
dbDIR="$WF_DIR/assets/databases/IDdbs"

bash "$WF_DIR/run_workflow.sh" \\
  -i $PROJECT \\
  -e arFORMAT \\
  -n "-profile docker --max_memory 7.GB --max_cpus 4 --runBASESPACE TRUE --input \$inputDIR/samplesheet.csv" \\
  -l \$inputDIR/labResults.csv \\
  -m \$metadataPATH
EOF

cat > "$OUTDIR/run_arREPORTER.sh" <<EOF
inputDIR="\$HOME/output/$PROJECT/input/"
metadataPATH="\$inputDIR/${PROJECT}_metadata.csv"

bash "$WF_DIR/run_workflow.sh" \\
  -i $PROJECT \\
  -e arREPORT \\
  -n "-profile docker --max_memory 7.GB --max_cpus 4 --runBASESPACE TRUE --input \$inputDIR/samplesheet.csv" \\
  -l \$inputDIR/labResults.csv \\
  -o \$metadataPATH
EOF

cat > "$OUTDIR/run_arOutbreak.sh" <<EOF
inputDIR="\$HOME/output/$PROJECT/input/"
metadataPATH="\$inputDIR/${PROJECT}_metadata.csv"

bash "$WF_DIR/run_workflow.sh" \\
  -i $PROJECT \\
  -e outbreakANALYSIS \\
  -n "-profile docker --max_memory 7.GB --max_cpus 4 --runBASESPACE TRUE --outbreak_species $outbreak_species --ref_samples \$HOME/output/$PROJECT/input/ref_samples.csv --input \$HOME/output/$PROJECT/input/samplesheet.csv" \\
  -m \$metadataPATH
EOF

chmod +x "$OUTDIR/run_arANALYZER.sh" "$OUTDIR/run_arFORMATTER.sh" "$OUTDIR/run_arREPORTER.sh" "$OUTDIR/run_arOutbreak.sh"

total_selected=$(( $(wc -l < "$SELECTED_ALL") - 1 ))
total_refs=$(( $(wc -l < "$REF_SAMPLES") ))

echo "Prepared outbreak input set for project: $PROJECT"
echo "  source samples:    $src_count"
echo "  reference samples: $total_refs"
echo "  total samples:     $total_selected"
echo "  outbreak species:  $outbreak_species"
echo "  output directory:  $OUTDIR"
echo ""
echo "Created files:"
echo "  $MATCHED_DB"
echo "  $METADATA_OUT"
echo "  $OUTDIR/labResults.csv"
echo "  $OUTDIR/samplesheet.csv"
echo "  $OUTDIR/ref_samples.csv"
echo "  $OUTDIR/${PROJECT}_metadata.csv"
echo "  $OUTDIR/run_arANALYZER.sh"
echo "  $OUTDIR/run_arFORMATTER.sh"
echo "  $OUTDIR/run_arREPORTER.sh"
echo "  $OUTDIR/run_arOutbreak.sh"
