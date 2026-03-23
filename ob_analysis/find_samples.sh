#!/usr/bin/env bash
set -euo pipefail

# ---- config ----
SAMPLES_FILE="${SAMPLES_FILE:-$HOME/workflows/ODHL_AR/ob_analysis/samples.csv}"         # sampleID,species (comma or tab)
AR_PASS_TSV="${AR_PASS_TSV:-$HOME/workflows/ODHL_AR/ob_analysis/ar_pass.tsv}"          # now local, TSV
DB_MASTER_CSV="${DB_MASTER_CSV:-$HOME/workflows/ODHL_AR/assets/databases/IDdbs/db_master.csv}" # CSV
OUT="${OUT:-$HOME/workflows/ODHL_AR/ob_analysis/tmp/matched_database.csv}"
MISSING_OUT="${MISSING_OUT:-$HOME/workflows/ODHL_AR/ob_analysis/tmp/find_samples_missing.txt}"

mkdir -p "$(dirname "$OUT")"

# sanity checks (non-fatal if ar_pass missing; we still try db_master)
[[ -f "$SAMPLES_FILE" ]]  || { echo "ERROR: samples file not found: $SAMPLES_FILE" >&2; exit 1; }
[[ -f "$DB_MASTER_CSV" ]] || { echo "WARN: db_master CSV not found: $DB_MASTER_CSV" >&2; }

awk -v SAMPLES="$SAMPLES_FILE" -v ARPASS="$AR_PASS_TSV" -v DBM="$DB_MASTER_CSV" -v OUTFILE="$OUT" -v MISSFILE="$MISSING_OUT" '
function up(s){ return toupper(s) }
function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
function trim(s){ return ltrim(rtrim(s)) }

BEGIN{
    OFS=","

    # ---- read samples (CSV or TSV: FS = comma or tab) ----
    FS="[,\t]"
    while ((getline line < SAMPLES) > 0) {
        sub(/\r$/,"",line)
        line = trim(line)
        if (line=="") continue
        n = split(line, a, FS)
        sid = up(trim(a[1]))
        sp  = (n>=2 ? trim(a[2]) : "")
        if (sid=="" || sid=="SAMPLEID") continue
        species[sid] = sp
        samples[sid] = 1
        total++
    }
    close(SAMPLES)

    # ---- read ar_pass.tsv (fallback) if present ----
    if ((getline hdr < ARPASS) > 0) {
        # parse header to locate columns by name (layout may vary)
        sub(/\r$/,"",hdr)
        n = split(hdr, H, "\t")
        col_id   = 0; col_proj = 0
        for (i=1; i<=n; i++) {
            h = trim(H[i])
            if (h == "entity:ar_pass_id")        col_id   = i
            if (h == "basespace_collection_id")   col_proj = i
        }
        if (col_id == 0 || col_proj == 0) {
            print "WARN: ar_pass.tsv missing required header(s) (entity:ar_pass_id, basespace_collection_id) — skipping" > "/dev/stderr"
        } else {
            while ((getline line < ARPASS) > 0) {
                sub(/\r$/,"",line); if (line=="") continue
                n = split(line, a, "\t")
                id   = up(trim(a[col_id]))
                proj = trim(a[col_proj])
                if (id!="" && proj!="") proj_ar[id] = proj
            }
        }
        close(ARPASS)
    }

    # ---- read db_master.csv (primary) ----
    if ((getline hdr2 < DBM) > 0) {
        while ((getline line < DBM) > 0) {
            sub(/\r$/,"",line); if (line=="") continue
            n = split(line, a, ",")
            proj = trim(a[1])         # PROJECT_ID
            oid  = up(trim(a[2]))     # OHIO_ID, may be like 24AR005261-OH-... or 24AR005261_KF...
            if (oid!="") {
                srr = trim(a[4]); sam = trim(a[5])
                complete = (srr!="" && srr!="NA" && sam!="" && sam!="NA")
                # prefer complete rows (SRRID + SAMID filled); ignore a partial if complete already stored
                if (complete || !(oid in proj_dbm))
                    proj_dbm[oid] = proj

                # prefix before first "_" OR "-" -> handles both forms
                short = oid
                sub(/[_-].*/, "", short)
                if (complete || !(short in proj_dbm_short)) proj_dbm_short[short] = proj
            }
        }
        close(DBM)
    }

    # ---- resolve each sample ----
    found_count = 0
    for (sid in samples) {
        if (sid in proj_dbm) {
            found[sid] = proj_dbm[sid]
        } else if (sid in proj_dbm_short) {
            found[sid] = proj_dbm_short[sid]
        } else if (sid in proj_ar) {
            found[sid] = proj_ar[sid]
        } else {
            missing[sid] = 1
        }
    }
    for (k in found) found_count++

    # ---- print stats (stderr so stdout stays as clean CSV) ----
    print "########################################" > "/dev/stderr"
    print "total number of samples in list: " total > "/dev/stderr"
    print "total number of unique samples found: " found_count > "/dev/stderr"
    print "########################################" > "/dev/stderr"

    # ---- missing list -> file + stderr ----
    if (found_count < total) {
        print "samples not found:" > "/dev/stderr"
        for (sid in species) {
            if (!(sid in found)) {
                print sid OFS species[sid] > "/dev/stderr"
                print sid OFS species[sid] > MISSFILE
            }
        }
        print "########################################" > "/dev/stderr"
    } else {
        close(MISSFILE); system("> " MISSFILE)
    }

    # ---- write matched CSV (with header) ----
    print "sampleID,species,projectID" > OUTFILE
    for (sid in found) print sid, species[sid], found[sid] >> OUTFILE
}
'

cat "$OUT"
echo "Wrote: $OUT" >&2
[[ -s "$MISSING_OUT" ]] && echo "Missing samples: $MISSING_OUT" >&2
