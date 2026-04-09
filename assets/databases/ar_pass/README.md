# ar_pass tables

Canonical storage for local ar_pass table snapshots.

Files:
- `ar_pass.tsv`: active table used by ob_analysis and DB maintenance.
- `archive/`: older snapshots retained for provenance and rollback.

Suggested naming for archived snapshots:
- `ar_pass_YYYY-MM-DD.tsv`
