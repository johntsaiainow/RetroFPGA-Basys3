#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v verilator >/dev/null || { echo 'verilator not found' >&2; exit 1; }
mkdir -p build/tutorial-tests/sap1
verilator --binary --timing --assert -Wno-fatal --top-module tb_sap1_core \
  --Mdir build/tutorial-tests/sap1 \
  cores/sap1/sap1_core.sv docs/tutorials/examples/t010/tb_sap1_core.sv
./build/tutorial-tests/sap1/Vtb_sap1_core
