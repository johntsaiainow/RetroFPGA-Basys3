#!/usr/bin/env python3

from pathlib import Path
import shutil

p = Path("rtl/retrofpga_top.sv")
original = p.read_text()
s = original

def replace_once(old, new):
    global s
    count = s.count(old)
    if count != 1:
        raise RuntimeError(
            f"Expected one matching anchor, found {count}:\n{old}"
        )
    s = s.replace(old, new, 1)

for marker in (
    "keyboard_accepted_edge",
    "keyboard_edge_counters",
    "diagnostics_renderer",
    "diagnostics_active",
):
    if marker in s:
        raise RuntimeError(f"Already integrated: {marker}")

replace_once(
    "    logic keyboard_timeout_error;",
    """    logic keyboard_timeout_error;
    logic keyboard_accepted_edge;
    logic diagnostics_active;

    logic [15:0] ps2_raw_edges;
    logic [15:0] ps2_accepted_edges;
    logic [15:0] ps2_valid_frames;
    logic [15:0] ps2_frame_errors;
    logic [15:0] ps2_timeouts;

    logic [11:0] diagnostics_rgb;"""
)

replace_once(
    """        .frame_error(keyboard_frame_error),
        .timeout_error(keyboard_timeout_error)
    );""",
    """        .frame_error(keyboard_frame_error),
        .accepted_edge(keyboard_accepted_edge),
        .timeout_error(keyboard_timeout_error)
    );"""
)

replace_once(
    "    pixel_enable pixel_clock",
    """    // Tutorial 014: PS/2 edge and frame counters.
    ps2_edge_counters keyboard_edge_counters (
        .clk(clk),
        .rst(reset_sync),
        .ps2_clk(ps2_clk),
        .accepted_edge(keyboard_accepted_edge),
        .scan_valid(keyboard_scan_valid),
        .frame_error(keyboard_frame_error),
        .timeout_error(keyboard_timeout_error),
        .raw_edge_count(ps2_raw_edges),
        .accepted_edge_count(ps2_accepted_edges),
        .valid_frame_count(ps2_valid_frames),
        .frame_error_count(ps2_frame_errors),
        .timeout_count(ps2_timeouts)
    );

    pixel_enable pixel_clock"""
)

replace_once(
    ".boot_request(boot_request), .booting(booting));",
    """.boot_request(boot_request), .booting(booting),
        .diagnostics_active(diagnostics_active));"""
)

replace_once(
    "    // Tutorial 012: board-independent input routing.",
    """    // Tutorial 014: PS/2 VGA diagnostics.
    keyboard_diagnostics_renderer diagnostics_renderer (
        .x(x),
        .y(y),
        .video_active(video_active),
        .raw_edges(ps2_raw_edges),
        .accepted_edges(ps2_accepted_edges),
        .valid_frames(ps2_valid_frames),
        .frame_errors(ps2_frame_errors),
        .timeouts(ps2_timeouts),
        .scan_code(led_scan_code),
        .rgb(diagnostics_rgb)
    );

    // Tutorial 012: board-independent input routing."""
)

# Match only the Input Router instance.
replace_once(
    """retrofpga_input_router input_router (
        .menu_active(menu_active),""",
    """retrofpga_input_router input_router (
        .menu_active(menu_active),
        .diagnostics_active(diagnostics_active),"""
)

replace_once(
    """    always_comb begin
        final_rgb = {title_r, title_g, title_b};
        if (menu_opaque) final_rgb = menu_rgb;
        if (sap_active) final_rgb = sap_rgb;
        if (!video_active) final_rgb = 12'h000;
    end""",
    """    always_comb begin
        final_rgb = 12'h000;

        if (diagnostics_active) begin
            final_rgb = diagnostics_rgb;
        end else if (sap_active) begin
            final_rgb = sap_rgb;
        end else begin
            final_rgb = {title_r, title_g, title_b};
            if (menu_opaque)
                final_rgb = menu_rgb;
        end

        if (!video_active)
            final_rgb = 12'h000;
    end"""
)

# Suppress only intentional empty connections in the
# existing LED diagnostics instance.
replace_once(
    """    ps2_keyboard_diagnostics keyboard_diagnostics (""",
    """    /* verilator lint_off PINCONNECTEMPTY */
    ps2_keyboard_diagnostics keyboard_diagnostics ("""
)

replace_once(
    """        .led_timeout_activity(led_timeout_activity)
    );""",
    """        .led_timeout_activity(led_timeout_activity)
    );
    /* verilator lint_on PINCONNECTEMPTY */"""
)

backup = p.with_name(p.name + ".phase49d6-backup")

if backup.exists():
    raise RuntimeError(f"Backup exists: {backup}")

shutil.copy2(p, backup)
p.write_text(s)

print("PASS: Top Level Diagnostics Integration")
print("Backup:", backup)
