#!/usr/bin/env bash
set -euo pipefail

# Legacy compatibility wrapper.
# Use run_ob_prep.sh as the single deployment entrypoint.

OB_DIR="${OB_DIR:-$(cd "$(dirname "$0")" && pwd)}"
exec bash "$OB_DIR/run_ob_prep.sh" "$@"
