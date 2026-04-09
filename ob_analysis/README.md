# ob_analysis

Single-entry outbreak prep for ODHL_AR.

Use one input file (`samples.csv`) and one deployment script (`run_ob_prep.sh`).

## Input format

Put one sample per line in `samples.csv`.

Supported forms:

1. `sampleID`
2. `sampleID,species` (species is optional and ignored by the prep selector)
3. `date<TAB>sampleID` (your current format)

Example:

```
04-06-2026	26AR000632
04-06-2026	26AR000720
```

## One-command run

From `ob_analysis`:

```bash
bash run_ob_prep.sh OB26001
```

If project ID is omitted, default is `OB<YYMMDD>`.

What this script does end-to-end:

1. Reads source sample IDs from `samples.csv`.
2. Resolves species and project IDs from `ar_pass.tsv`.
3. Fails fast if any source sample is missing in `ar_pass.tsv`.
4. Selects random same-species reference samples from `ar_pass.tsv` to reach 15 total.
5. Builds `tmp/matched_database.csv` and verifies BaseSpace access.
6. Builds NCBI metadata in-script from `assets/databases/ar_pass/ar_pass.tsv`, `extra_meta.tsv`, and `db_master.csv`.
7. Writes ready-to-run files into `$HOME/output/<PROJECT>/input/`:
   `samplesheet.csv`, `labResults.csv`, `ref_samples.csv`, `<PROJECT>_metadata.csv`.
8. Generates run scripts:
   `run_arANALYZER.sh`, `run_arFORMATTER.sh`, `run_arREPORTER.sh`, `run_arOutbreak.sh`.

## Important behavior

1. Source sample species is inferred from `ar_pass.tsv` (`sequence_classification`).
2. References are selected only from the same inferred species.
3. Default total sample target is 15 (`TARGET_TOTAL=15`).
4. If fewer references exist than needed, the script continues with all available refs and warns.
5. If source samples map to mixed species, the script exits with an error.

## Environment overrides

Optional environment variables:

1. `SAMPLES_FILE` (default: `ob_analysis/samples.csv`)
2. `AR_PASS_TSV` (default: `assets/databases/ar_pass/ar_pass.tsv`)
3. `EXTRA_TSV` (default: `ob_analysis/extra_meta.tsv`)
4. `DB_MASTER_CSV` (default: `assets/databases/IDdbs/db_master.csv`)
5. `TARGET_TOTAL` (default: `15`)
6. `PROJECT` (alternative to positional project argument)
7. `BS` (optional explicit path to BaseSpace CLI)

## Repository hygiene

1. `ob_analysis/tmp` is treated as generated output.
2. `ob_analysis/.gitignore` ignores all files in `tmp/` except `tmp/.gitkeep`.

## DB maintenance

`maintain_db.sh` is unchanged and still updates `assets/databases/IDdbs/db_master.csv` in place with an archive copy. It now reads the canonical ar_pass table from `assets/databases/ar_pass/ar_pass.tsv` by default.
