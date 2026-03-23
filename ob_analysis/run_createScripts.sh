#!/usr/bin/env bash
set -euo pipefail

# Must be run from the ob_analysis directory (or set OB_DIR)
OB_DIR="${OB_DIR:-$(cd "$(dirname "$0")" && pwd)}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <PROJECT>" >&2
  echo "  Prerequisites: run find_samples.sh and create_metadata.sh first" >&2
  exit 1
fi

PROJECT="$1"
OUTDIR="$HOME/output/$PROJECT/input"
mkdir -p "$OUTDIR"

# ── Inputs ────────────────────────────────────────────────────────────────────
SAMPLES="$OB_DIR/samples.csv"
SPECIES_CSV="$OB_DIR/species.csv"
MATCHED="$OB_DIR/tmp/matched_database.csv"
META_SRC="$OB_DIR/tmp/metadata_for_script.csv"

[[ -f "$SAMPLES"     ]] || { echo "ERROR: samples.csv not found: $SAMPLES" >&2; exit 1; }
[[ -f "$SPECIES_CSV" ]] || { echo "ERROR: species.csv not found: $SPECIES_CSV" >&2; exit 1; }
[[ -f "$MATCHED"     ]] || { echo "ERROR: tmp/matched_database.csv not found — run find_samples.sh first" >&2; exit 1; }
[[ -f "$META_SRC"    ]] || { echo "ERROR: tmp/metadata_for_script.csv not found — run create_metadata.sh first" >&2; exit 1; }

# Read species name (first non-blank line of species.csv)
OUTBREAK_SPECIES=$(grep -v '^[[:space:]]*$' "$SPECIES_CSV" | head -1 | tr -d '\r')

# ── ref_samples.csv from samples.csv (rows where type == "ref") ──────────────
awk -F',' '$2=="ref" && $1!="" { print $1 }' "$SAMPLES" > "$OUTDIR/ref_samples.csv"

# ── labResults.csv from matched_database.csv (sampleID-projectID,species) ────
echo "sample,results" > "$OUTDIR/labResults.csv"
awk -F',' -v species="$OUTBREAK_SPECIES" 'NR>1 && $1!="" && $3!="" {
    proj=$3; sub(/_AR$/, "", proj)
    print $1 "-" proj "," species
}' "$MATCHED" >> "$OUTDIR/labResults.csv"

# ── samplesheet.csv from matched_database.csv ─────────────────────────────────
# sample name = sampleID-projectID (strip _AR suffix from project for filename)
echo "sample,fastq_1,fastq_2" > "$OUTDIR/samplesheet.csv"
awk -F',' 'NR>1 && $1!="" && $3!="" {
    proj=$3; sub(/_AR$/, "", proj)
    name=$1 "-" proj
    print name "," name ".R1.fastq.gz," name ".R2.fastq.gz"
}' "$MATCHED" >> "$OUTDIR/samplesheet.csv"

# ── metadata file (named so ls *_metadata* resolves it) ───────────────────────
cp "$META_SRC" "$OUTDIR/${PROJECT}_metadata.csv"

# ── run_arANALYZER.sh ────────────────────────────────────────────────────────
cat > "$OUTDIR/run_arANALYZER.sh" <<EOF
bash run_workflow.sh \\
	-i $PROJECT \\
	-e arANALYSIS \\
	-n "-profile docker --max_memory 7.GB --max_cpus 4 --runBASESPACE TRUE --input \$HOME/output/$PROJECT/input/samplesheet.csv" \\
	-l  \$HOME/output/$PROJECT/input/labResults.csv
EOF

# ── run_arFORMATTER.sh ───────────────────────────────────────────────────────
cat > "$OUTDIR/run_arFORMATTER.sh" <<EOF
inputDIR="\$HOME/output/$PROJECT/input/"
metadataPATH=\$(ls \$inputDIR/*_metadata*)
dbDIR="\$HOME/workflows/ODHL_AR/assets/databases/IDdbs"

bash run_workflow.sh \\
	-i $PROJECT \\
	-e arFORMAT \\
	-n "-profile docker --max_memory 7.GB --max_cpus 4 --runBASESPACE TRUE --input \$inputDIR/samplesheet.csv" \\
	-l \$inputDIR/labResults.csv \\
	-m \$metadataPATH

cp \$dbDIR/db_master.csv \$dbDIR/cached/db_master_$PROJECT.csv
NEW_RESULTS="\$HOME/output/$PROJECT/results/arFORMAT/ncbi_prep/id_db_results_preNCBI.csv"
db_header=\$(head -n 1 \$dbDIR/db_master.csv)
(tail -n +2 \$dbDIR/db_master.csv && tail -n +2 \$NEW_RESULTS) | sort -t, -k3,3 > tmp
printf '%s\n' "\$db_header" > \$dbDIR/db_master.csv
cat tmp >> \$dbDIR/db_master.csv
tail \$dbDIR/db_master.csv
rm tmp

awk -F"," '{print \$2}' \$dbDIR/db_master.csv | sed "s/-OH-VH[0-9].*//g" | sort | uniq -c | grep "2 "
EOF

# ── run_arREPORTER.sh ────────────────────────────────────────────────────────
cat > "$OUTDIR/run_arREPORTER.sh" <<EOF
inputDIR="\$HOME/output/$PROJECT/input/"
metadataPATH=\$(ls \$inputDIR/*_metadata*)
dbDIR="\$HOME/workflows/ODHL_AR/assets/databases/IDdbs"

bash run_workflow.sh \\
	-i $PROJECT \\
	-e arREPORT \\
	-n "-profile docker --max_memory 7.GB --max_cpus 4 --runBASESPACE TRUE --input \$inputDIR/samplesheet.csv" \\
	-l \$inputDIR/labResults.csv \\
	-o \$metadataPATH

cp \$dbDIR/db_master.csv \$dbDIR/cached/db_master_$PROJECT.csv
NEW_DB="\$HOME/output/$PROJECT/results/arREPORT/ncbi_post/id_db_master.csv"
db_header=\$(head -n 1 \$dbDIR/db_master.csv)
awk -F, 'FNR==1 {next}
{
    key = \$1 FS \$2 FS \$3
    if (!(key in seen) || (\$4 != "" && \$5 != "")) {
        row[key] = \$0
        if (\$4 != "" && \$5 != "") seen[key] = 1
    }
}
END {
    for (k in row) print row[k]
}' \$dbDIR/db_master.csv \$NEW_DB | sort -t, -k3,3 > tmp
printf '%s\n' "\$db_header" > \$dbDIR/db_master.csv
cat tmp >> \$dbDIR/db_master.csv
rm tmp

grep "$PROJECT" \$dbDIR/db_master.csv
cat \$HOME/output/$PROJECT/results/arFORMAT/post_process/quality_results.csv
EOF

# ── run_arOutbreak.sh ────────────────────────────────────────────────────────
cat > "$OUTDIR/run_arOutbreak.sh" <<EOF
inputDIR="\$HOME/output/$PROJECT/input/"
metadataPATH=\$(ls \$inputDIR/*_metadata*)

bash run_workflow.sh \\
        -i $PROJECT \\
        -e outbreakANALYSIS \\
        -n "-profile docker --max_memory 7.GB --max_cpus 4 --runBASESPACE TRUE --outbreak_species $OUTBREAK_SPECIES --ref_samples \$HOME/output/$PROJECT/input/ref_samples.csv --input \$HOME/output/$PROJECT/input/samplesheet.csv" \\
        -m \$metadataPATH
EOF

echo "Created in $OUTDIR:"
echo "  labResults.csv       ($(tail -n +2 "$OUTDIR/labResults.csv" | wc -l | tr -d ' ') samples)"
echo "  samplesheet.csv      ($(tail -n +2 "$OUTDIR/samplesheet.csv" | wc -l | tr -d ' ') samples)"
echo "  ref_samples.csv      ($(wc -l < "$OUTDIR/ref_samples.csv" | tr -d ' ') refs — species: $OUTBREAK_SPECIES)"
echo "  ${PROJECT}_metadata.csv"
echo "  run_arANALYZER.sh"
echo "  run_arFORMATTER.sh"
echo "  run_arREPORTER.sh"
echo "  run_arOutbreak.sh"
