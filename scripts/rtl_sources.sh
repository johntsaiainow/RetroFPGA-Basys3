#!/usr/bin/env bash

# Shared RTL source list for simulation and lint.
# Excludes alternative debug top-levels.

RTL=(
    rtl/boot/core_registry.sv
    rtl/boot/boot_menu_controller.sv
    rtl/boot/counter.sv

    rtl/common/bin_to_bcd.sv
    rtl/common/retrofpga_input_router.sv
    rtl/common/sap1_execution_controller.sv

    rtl/input/button_debounce.sv
    rtl/input/ps2_keyboard_receiver.sv
    rtl/input/ps2_keyboard_diagnostics.sv
    rtl/input/ps2_edge_counters.sv

    rtl/video/font_rom.sv
    rtl/video/pixel_enable.sv
    rtl/video/vga_timing.sv
    rtl/video/text_renderer.sv
    rtl/video/pixel_renderer.sv
    rtl/video/boot_menu_renderer.sv
    rtl/video/keyboard_diagnostics_renderer.sv
    rtl/video/sap1_vga_monitor.sv

    rtl/retrofpga_top.sv
)

# Discover SAP-1 core without assuming its location.
while IFS= read -r file; do
    RTL+=("$file")
done < <(
    find rtl -type f -name '*.sv' \
        ! -path 'rtl/debug/*' \
        ! -path 'rtl/retrofpga_top.sv' \
        ! -path 'rtl/boot/*' \
        ! -path 'rtl/common/*' \
        ! -path 'rtl/input/*' \
        ! -path 'rtl/video/*' \
        | sort
)

# Locate the SAP-1 core used by the tutorial.
mapfile -t SAP1_CORE_FILES < <(
    grep -R -l -E \
        '^[[:space:]]*module[[:space:]]+sap1_core([[:space:]#(;]|$)' \
        rtl docs cores \
        --include='*.sv' --include='*.v' \
        2>/dev/null | sort -u
)

if (( ${#SAP1_CORE_FILES[@]} != 1 )); then
    echo "ERROR: Expected one SAP-1 core, found ${#SAP1_CORE_FILES[@]}" >&2
    printf '%s\n' "${SAP1_CORE_FILES[@]}" >&2
    return 1 2>/dev/null || exit 1
fi

RTL+=("${SAP1_CORE_FILES[0]}")
echo "SAP-1 CORE: ${SAP1_CORE_FILES[0]}"
