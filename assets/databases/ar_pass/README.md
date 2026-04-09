# ar_pass tables

Canonical storage for local ar_pass table snapshots.

Files:
- `ar_pass.tsv`: active table used by ob_analysis and DB maintenance.
- `archive/`: older snapshots retained for provenance and rollback.
- `install_ar_pass.sh`: installs a new active table and archives the current one automatically.

Suggested naming for archived snapshots:
- `ar_pass_YYYY-MM-DD.tsv`

Install a new table:

```bash
bash assets/databases/ar_pass/install_ar_pass.sh /path/to/new_ar_pass.tsv
```

Move the source file instead of copying it:

```bash
bash assets/databases/ar_pass/install_ar_pass.sh --move /path/to/new_ar_pass.tsv
```
