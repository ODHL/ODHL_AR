# ob_analysis — ODHL AR Outbreak/BaseSpace Metadata Workflow

This directory contains scripts and supporting data for resolving a list of AR
specimen IDs to their BaseSpace project IDs, then generating a metadata CSV
ready for `core_ncbi_prep.sh` (NCBI submission pipeline).

---

## Workflow Overview

```
ob_analysis/
├── samples.csv          ← your input: sampleID,species
├── ar_pass.tsv          ← local Terra table (refresh as needed)
├── extra_meta.tsv       ← supplemental metadata fallback
│
├── find_samples.sh  ────────────────────────────────► tmp/matched_database.csv
│       looks up project IDs in db_master.csv (primary) and ar_pass.tsv
│
├── create_metadata.sh  ──────────────────────────────► tmp/metadata_for_script.csv
│       pulls full metadata from db_master.csv + ar_pass.tsv + extra_meta.tsv   tmp/missing_samples.txt
│
├── check_bs_access.sh  ─────────────────────────────► pass/fail per project (stderr)
│       verifies BaseSpace access to all projects before running the pipeline
│
├── run_createScripts.sh <PROJECT>  ─────────────────► $HOME/output/PROJECT/input/
│       builds labResults.csv, samplesheet.csv, metadata file,
│       and generates the four run_ar*.sh workflow scripts
│
└── maintain_db.sh      merge, deduplicate, and clean OHIO_IDs in db_master
                         (external db_master.csv, lives in assets/databases/)

tmp/   ← all generated/intermediate files (safe to delete and regenerate)
```

---

## File Reference

### Input files

| File | Description |
|---|---|
| `samples.csv` | Your working list of specimen IDs to process. One row per sample: `sampleID,species`. No header required. |
| `ar_pass.tsv` | Local copy of the Terra `ar_pass` data table (TSV). Source for specimen_id, isolation_source, collection_date, and sequence_classification. |
| `extra_meta.tsv` | Supplemental metadata (specimen_id, isolation_source, collect_date). Fallback when a sample is absent from `ar_pass.tsv`. |
| `db_master.csv` | Canonical master database at `assets/databases/IDdbs/db_master.csv`. Primary source for project IDs, WGS/SRR accessions, and sequencer date. |

### Generated files (written to `tmp/`)

All script-generated files land in the `tmp/` subdirectory so they are easy
to distinguish from the permanent input files. `tmp/` can be safely deleted
and recreated by re-running the scripts.

| File | Created by | Description |
|---|---|---|
| `tmp/matched_database.csv` | `find_samples.sh` | Quick lookup result: sampleID → projectID. |
| `tmp/find_samples_missing.txt` | `find_samples.sh` | Sample IDs not resolved from any source (empty if all found). |
| `tmp/metadata_for_script.csv` | `create_metadata.sh` | Full 15-column metadata CSV for `core_ncbi_prep.sh`. |
| `tmp/missing_samples.txt` | `create_metadata.sh` | Sample IDs not resolved from any source. |

### External files managed by `maintain_db.sh`

| File | Description |
|---|---|
| `assets/databases/IDdbs/db_master.csv` | Updated in-place after each run. |
| `assets/databases/IDdbs/archive/db_master_<date>.csv` | Archive copy made before each update. |

---

## Step-by-Step Usage

### Step 1 — Populate `samples.csv`

Create or edit `samples.csv` with the specimen IDs you want to process:

```
25AR002067,Acinetobacter
25AR002066,Acinetobacter
25AR001971,Klebsiella
```

No header line is needed. A second column (species) is optional but recommended.

---

### Step 2 — Find project IDs (quick lookup)

```bash
cd $HOME/workflows/ODHL_AR/ob_analysis

bash find_samples.sh
```

Diagnostic output (totals, missing IDs) goes to **stderr**.  
Matched results are written to `tmp/matched_database.csv` and also printed to **stdout**, so you can pipe or redirect:

```bash
bash find_samples.sh > tmp/matched.csv 2>find_log.txt
```

**Override paths with environment variables:**

```bash
SAMPLES_FILE=/path/to/my_samples.csv \
AR_PASS_TSV=/path/to/ar_pass.tsv \
DB_MASTER_CSV=/path/to/db_master.csv \
OUT=/path/to/output.csv \
bash find_samples.sh
```

**Lookup priority:** db_master.csv (exact match) → db_master.csv (prefix match, strips `_` / `-` suffix) → ar_pass.tsv (exact match).

---

### Step 3 — Build full metadata for NCBI submission

```bash
bash create_metadata.sh
```

Reads `samples.csv` and writes `metadata_for_script.csv` (15-column format for
`core_ncbi_prep.sh`). Resolution priority per field:

| Field | Primary | Fallback |
|---|---|---|
| `basespace_collection_id`, `wgs_id`, `srr_number`, `wgs_date_put_on_sequencer` | `db_master.csv` (complete rows first) | `ar_pass.tsv` |
| `specimen_id`, `isolation_source`, `collection_date`, `sequence_classification` | `ar_pass.tsv` | `extra_meta.tsv` |

Any sample not found in any source is listed in `missing_samples.txt`.

**Override paths with flags:**

```bash
bash create_metadata.sh \
  -s /path/to/samples.csv \
  -m /path/to/ar_pass.tsv \
  -e /path/to/extra_meta.tsv \
  -d /path/to/db_master.csv \
  -o /path/to/output.csv \
  -x /path/to/missing.txt
```

---

### Step 4 — Check BaseSpace access

Before running the pipeline, verify you have access to every project:

```bash
bash check_bs_access.sh
```

Reads `tmp/matched_database.csv`, checks each unique project against the
BaseSpace CLI, and reports which ones are accessible vs. need permissions.
Exit code is non-zero if any project fails, so it can be used as a gate:

```
  OK          OH-VH01632-250221
  NO ACCESS   OH-VH00648-260220
  ...
  accessible:   11 / 12
  Need access to 1 project(s):
    OH-VH00648-260220
```

Request access for any failing projects, then re-run to confirm before
proceeding to Step 5.

---

### Step 5 — Set up the project run directory

Once Steps 2 and 3 are complete, generate the run directory and workflow scripts:

```bash
bash run_createScripts.sh <PROJECT>
```

This creates `$HOME/output/<PROJECT>/input/` containing:

| File | Source |
|---|---|
| `labResults.csv` | built from `samples.csv` |
| `samplesheet.csv` | built from `tmp/matched_database.csv` |
| `<PROJECT>_metadata.csv` | copied from `tmp/metadata_for_script.csv` |
| `run_arANALYZER.sh` | generated |
| `run_arFORMATTER.sh` | generated |
| `run_arREPORTER.sh` | generated |
| `run_arOutbreak.sh` | generated |

Then run each workflow script in sequence from the output directory.

---

## DB Maintenance

`maintain_db.sh` combines three operations in sequence — merge new ar_pass
entries, deduplicate by `(PROJECT_ID, OHIO_ID, WGSID)` keeping complete rows,
then strip run suffixes from `OHIO_ID` — and writes the result **directly back
to `db_master.csv`** (in-place). Before overwriting, the existing file is
archived to `assets/databases/IDdbs/archive/db_master_<YYYY-MM-DD>.csv`.

```bash
# Run from ob_analysis (uses default paths)
bash maintain_db.sh
```

Both input paths default to the standard locations, so no arguments are needed
in the normal case. You can still override with positional args:

```bash
bash maintain_db.sh /path/to/db_master.csv /path/to/ar_pass.tsv
```

Or with environment variables:

```bash
DB=/path/to/db_master.csv ARPASS=/path/to/ar_pass.tsv bash maintain_db.sh
```

The script prints two status lines to stderr on success:

```
Archived: .../archive/db_master_2026-03-20.csv
Updated:  .../db_master.csv
```

> **Requires GNU awk (`gawk`)** — uses `ARGIND` for multi-file processing.

---

## Common Issues

| Problem | Likely cause | Fix |
|---|---|---|
| Sample shows up in `missing_samples.txt` | Not yet in `ar_pass.tsv` or `extra_meta.tsv` | Add row to `extra_meta.tsv` or refresh `ar_pass.tsv` from Terra |
| `find_samples.sh` finds wrong project | Multiple runs for the same ID in db_master | Run `maintain_db.sh` to deduplicate, or add the ID to `ar_pass.tsv` (takes priority) |
| `create_metadata.sh` outputs empty ISO/date | Field blank in ar_pass; not in extra_meta | Add supplemental row to `extra_meta.tsv` |
| `maintain_db.sh` fails with awk error | System `awk` is mawk/nawk, not gawk | Install gawk or call explicitly: `gawk -f ...` |
