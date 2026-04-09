#!/usr/bin/env bash
set -euo pipefail

# Defaults
HOME_PATH="$HOME/workflows/ODHL_AR/ob_analysis"
SAMPLES_FILE="$HOME_PATH/samples.csv"      # sampleID[,species] (CSV or TSV)
MASTER_TSV="$HOME_PATH/ar_pass.tsv"        # authoritative metadata; TSV
EXTRA_TSV="$HOME_PATH/extra_meta.tsv"      # fallback metadata; TSV
DB_MASTER_CSV="${DB_MASTER_CSV:-$HOME/workflows/ODHL_AR/assets/databases/IDdbs/db_master.csv}"
OUT="$HOME_PATH/tmp/metadata_for_script.csv"
MISSING="$HOME_PATH/tmp/missing_samples.txt"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--samples) SAMPLES_FILE="$2"; shift 2 ;;
    -m|--master)  MASTER_TSV="$2";  shift 2 ;;
    -e|--extra)   EXTRA_TSV="$2";   shift 2 ;;
    -d|--db)      DB_MASTER_CSV="$2"; shift 2 ;;
    -o|--out)     OUT="$2";         shift 2 ;;
    -x|--missing) MISSING="$2";     shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$(dirname "$OUT")"

[[ -f "$SAMPLES_FILE" ]] || { echo "ERROR: samples file not found: $SAMPLES_FILE" >&2; exit 1; }
[[ -f "$MASTER_TSV"   ]] || { echo "ERROR: master TSV not found: $MASTER_TSV"   >&2; exit 1; }
[[ -f "$EXTRA_TSV"    ]] || { echo "WARN: extra TSV not found: $EXTRA_TSV (fallback limited)" >&2; EXTRA_TSV=""; }
[[ -f "$DB_MASTER_CSV" ]] || { echo "WARN: db_master CSV not found: $DB_MASTER_CSV (will rely on ar_pass only)" >&2; DB_MASTER_CSV=""; }

# Header required by core_ncbi_prep.sh
cat > "$OUT" <<'HDR'
sample_id,basespace_collection_id,specimen_id,wgs_id,srr_number,wgs_date_put_on_sequencer,sequence_classification,filler1,filler2,filler3,isolation_source,filler4,filler5,collection_date,trailing_col
HDR
printf 'sampleID,species,projectID\n' > "$MISSING"

awk -v SAMPLES="$SAMPLES_FILE" -v MASTER="$MASTER_TSV" -v EXTRA="$EXTRA_TSV" \
    -v DBM="$DB_MASTER_CSV" -v OUTFILE="$OUT" -v MISSFILE="$MISSING" '
function up(s){ return toupper(s) }
function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
function trim(s){ return ltrim(rtrim(s)) }
function nz(x, repl){ return (x=="" ? repl : x) }
function csv(f){ gsub(/\r$/,"",f); gsub(/"/,"\"\"",f); if(f ~ /[", ]/) return "\"" f "\""; return f }
function is_id(s){ s=up(trim(s)); return (s ~ /^[0-9]{2}AR[0-9]+([_-].*)?$/) }
function canon_id(s){ s=up(trim(s)); sub(/[_-].*/, "", s); return s }
function is_date(s){ s=trim(s); return (s ~ /^[0-9]{2}[-\/][0-9]{2}[-\/][0-9]{4}$/ || s ~ /^[0-9]{4}[-\/][0-9]{2}[-\/][0-9]{2}$/) }

BEGIN{
  OFS = ","

  # 1) Read requested samples (CSV or TSV)
  FS = "[,\t]"
  while ((getline line < SAMPLES) > 0) {
    sub(/\r$/,"",line); line = trim(line)
    if (line=="") continue
    n = split(line, a, FS)
    sid = ""
    c1 = trim(a[1]); c2 = (n>=2 ? trim(a[2]) : "")
    if (is_id(c1)) sid = canon_id(c1)
    else if (n>=2 && is_id(c2)) sid = canon_id(c2)
    if (sid=="" || sid=="SAMPLEID") continue
    samples[sid] = 1
    if (is_id(c1) && n>=2 && !is_id(c2) && !is_date(c2)) sp_input[sid] = c2
    else if (is_id(c2) && !is_date(c1)) sp_input[sid] = c1
    else sp_input[sid] = ""
    order[++N] = sid
  }
  close(SAMPLES)

  # 2) Read db_master.csv (primary for project/wgs/srr/date fields)
  #    Prefer complete rows (SRRID + SAMID both filled), same logic as find_samples.sh
  FS = ","
  if (DBM != "" && (getline hdr < DBM) > 0) {
    while ((getline line < DBM) > 0) {
      sub(/\r$/,"",line); if (line=="") continue
      split(line, a, FS)
      proj = trim(a[1]); oid = up(trim(a[2]))
      wgs  = trim(a[3]); srr = trim(a[4]); sam = trim(a[5]); dat = trim(a[6])
      if (oid=="") continue
      complete = (srr!="" && srr!="NA" && sam!="" && sam!="NA")
      if (complete || !(oid in D_proj)) {
        D_proj[oid] = proj; D_wgs[oid] = wgs
        D_srr[oid]  = srr;  D_dat[oid] = dat
      }
    }
    close(DBM)
  }

  # 3) Read MASTER (ar_pass.tsv) — primary for specimen_id, isolation_source,
  #    collection_date, sequence_classification; fallback for wgs/srr/date/project
  FS = "\t"
  if ((getline hdr < MASTER) <= 0) { print "ERROR: empty master TSV: " MASTER > "/dev/stderr"; exit 1 }
  sub(/\r$/,"",hdr)
  nh = split(hdr, H, FS)
  for (i=1;i<=nh;i++) mapM[H[i]] = i

  reqM = "entity:ar_pass_id basespace_collection_id collection_date isolation_source specimen_id wgs_id srr_number wgs_date_put_on_sequencer sequence_classification"
  split(reqM, RM, " ")
  for (i in RM) {
    if (!(RM[i] in mapM)) {
      printf("WARN: master TSV missing header: %s (will be blank where used)\n", RM[i]) > "/dev/stderr"
    }
  }

  while ((getline line < MASTER) > 0) {
    sub(/\r$/,"",line); if (line=="") continue
    split(line, a, FS)
    sid_raw = (("entity:ar_pass_id" in mapM) ? a[ mapM["entity:ar_pass_id"] ] : "")
    sid_key = up(trim(sid_raw))
    if (sid_key=="") continue
    M_sid[sid_key] = sid_raw
    M_bsc[sid_key] = (("basespace_collection_id"    in mapM) ? a[ mapM["basespace_collection_id"] ]    : "")
    M_cdt[sid_key] = (("collection_date"            in mapM) ? a[ mapM["collection_date"] ]            : "")
    M_iso[sid_key] = (("isolation_source"           in mapM) ? a[ mapM["isolation_source"] ]           : "")
    M_spc[sid_key] = (("specimen_id"                in mapM) ? a[ mapM["specimen_id"] ]                : "")
    M_wgs[sid_key] = (("wgs_id"                     in mapM) ? a[ mapM["wgs_id"] ]                     : "")
    M_srr[sid_key] = (("srr_number"                 in mapM) ? a[ mapM["srr_number"] ]                 : "")
    M_wdt[sid_key] = (("wgs_date_put_on_sequencer"  in mapM) ? a[ mapM["wgs_date_put_on_sequencer"] ]  : "")
    M_sc[sid_key]  = (("sequence_classification"    in mapM) ? a[ mapM["sequence_classification"] ]    : "")
  }
  close(MASTER)

  # 4) Read EXTRA (extra_meta.tsv) — fallback for isolation_source and collection_date
  if (EXTRA != "") {
    if ((getline hdr2 < EXTRA) > 0) {
      sub(/\r$/,"",hdr2)
      split(hdr2, E, FS)
      for (i=1;i<=length(E);i++) mapE[E[i]] = i
      need1="specimen_id"; need2="isolation_source"; need3="collect_date"
      if (!(need1 in mapE)) { printf("WARN: EXTRA missing %s\n", need1) > "/dev/stderr" }
      if (!(need2 in mapE)) { printf("WARN: EXTRA missing %s\n", need2) > "/dev/stderr" }
      if (!(need3 in mapE)) { printf("WARN: EXTRA missing %s\n", need3) > "/dev/stderr" }
      while ((getline line < EXTRA) > 0) {
        sub(/\r$/,"",line); if (line=="") continue
        split(line, b, FS)
        esid_raw = (("specimen_id" in mapE) ? b[ mapE["specimen_id"] ] : "")
        esid_key = up(trim(esid_raw))
        if (esid_key=="") continue
        E_sid[esid_key] = esid_raw
        E_iso[esid_key] = (("isolation_source" in mapE) ? b[ mapE["isolation_source"] ] : "")
        E_cdt[esid_key] = (("collect_date"     in mapE) ? b[ mapE["collect_date"] ]     : "")
      }
      close(EXTRA)
    }
  }

  # 5) Resolve each sample
  #    Priority: db_master (project/wgs/srr/date) > ar_pass > extra_meta
  found=0; miss=0
  for (i=1;i<=N;i++) {
    sid = order[i]

    in_master = (sid in M_sid)
    in_extra  = (sid in E_sid)

    if (!in_master && !in_extra) {
      sp  = sp_input[sid]
      proj_miss = (sid in D_proj) ? D_proj[sid] : ""
      print sid "," sp "," proj_miss >> MISSFILE
      miss++
      continue
    }

    # Fields exclusively from ar_pass / extra_meta
    sid_out = in_master ? M_sid[sid] : E_sid[sid]
    spc     = in_master ? M_spc[sid] : E_sid[sid]
    sc      = in_master ? M_sc[sid]  : ""
    iso     = in_master ? M_iso[sid] : ""
    cdt     = in_master ? M_cdt[sid] : ""
    # Fill iso/cdt from extra_meta if blank
    if ((iso=="" || iso=="NA") && (sid in E_iso)) iso = E_iso[sid]
    if ((cdt=="" || cdt=="NA") && (sid in E_cdt)) cdt = E_cdt[sid]

    # db_master takes priority for project/wgs/srr/date; fall back to ar_pass
    bsc = (sid in D_proj) ? D_proj[sid] : (in_master ? M_bsc[sid] : "")
    wgs = (sid in D_wgs)  ? D_wgs[sid]  : (in_master ? M_wgs[sid] : "")
    srr = (sid in D_srr)  ? D_srr[sid]  : (in_master ? M_srr[sid] : "")
    dat = (sid in D_dat)  ? D_dat[sid]  : (in_master ? M_wdt[sid] : "")

    printf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
      csv(sid_out), csv(bsc), csv(spc), csv(wgs), csv(srr), csv(dat), csv(sc),
      "", "", "", csv(iso), "", "", csv(cdt), "END") >> OUTFILE
    found++
  }

  print "########################################" > "/dev/stderr"
  print "total number of samples in list: " N > "/dev/stderr"
  print "total number of rows written: " found > "/dev/stderr"
  print "########################################" > "/dev/stderr"
  if (miss>0) {
    print "Missing " miss " sample(s) -> " MISSFILE > "/dev/stderr"
  } else {
    close(MISSFILE); system("> " MISSFILE)
    print "All requested samples were found." > "/dev/stderr"
  }
}
'
cat $MISSING
echo "Wrote: $OUT"
