#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/rtl_sources.sh

verilator \
    --lint-only --timing --trace \
    --top-module tb_retrofpga_top \
    "${RTL[@]}" \
    sim/tb_retrofpga_top.sv

verilator \
    --binary --timing --trace \
    --top-module tb_retrofpga_top \
    --Mdir build/verilator/top_integration \
    "${RTL[@]}" \
    sim/tb_retrofpga_top.sv

./build/verilator/top_integration/Vtb_retrofpga_top
