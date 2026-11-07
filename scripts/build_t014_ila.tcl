# Tutorial 014 - ILA Reset Capture
# Non-project debug insertion from isolated synthesis checkpoint.

set root [file normalize [file join [file dirname [info script]] ..]]
set outdir [file join $root build basys3 ila]
set dcp [file join $outdir t014_ila_synth.dcp]

if {![file exists $dcp]} {
    error "Missing synthesis checkpoint: $dcp"
}

puts "=== OPEN SYNTHESIS CHECKPOINT ==="
open_checkpoint $dcp

puts "=== CREATE ILA ==="
create_debug_core u_ila_t014 ila

set core [get_debug_cores u_ila_t014]
set_property C_DATA_DEPTH 1024 $core
set_property C_NUM_OF_PROBES 9 $core

# Find the actual 100 MHz clock network after the BUFG.
set bufgs [get_cells -hier -filter {REF_NAME == BUFG}]

if {[llength $bufgs] != 1} {
    error "Expected one BUFG, found [llength $bufgs]"
}

set clock_pins [get_pins -of_objects $bufgs \
    -filter {REF_PIN_NAME == O}]

set clock_nets [get_nets -of_objects $clock_pins]

if {[llength $clock_nets] != 1} {
    error "Unable to identify unique ILA clock"
}

connect_debug_port u_ila_t014/clk $clock_nets

proc require_net {name} {
    set nets [get_nets -quiet $name]
    if {[llength $nets] != 1} {
        error "Expected exactly one net for $name; found [llength $nets]"
    }
    return $nets
}

proc connect_scalar {index name} {
    connect_debug_port u_ila_t014/probe$index \
        [require_net $name]
}

proc connect_bus {index prefix width} {
    set nets [list]
    for {set i 0} {$i < $width} {incr i} {
        lappend nets [require_net "${prefix}\[$i\]"]
    }

    set_property port_width $width \
        [get_debug_ports u_ila_t014/probe$index]

    connect_debug_port u_ila_t014/probe$index $nets
}

puts "=== CONNECT PROBES ==="

connect_scalar 0 btn_reset_IBUF
connect_scalar 1 reset_sync
connect_scalar 2 ps2_clk_IBUF
connect_scalar 3 ps2_data_IBUF
connect_scalar 4 keyboard_accepted_edge
connect_scalar 5 keyboard_scan_valid
connect_bus 6 keyboard_scan_code 8
connect_bus 7 ps2_raw_edges 16
connect_bus 8 ps2_valid_frames 16

puts "=== VERIFY DEBUG CORES ==="
report_debug_core

puts "=== IMPLEMENTATION ==="
opt_design
place_design
phys_opt_design
route_design

puts "=== SAVE DEBUG CHECKPOINT ==="
write_checkpoint -force \
    [file join $outdir t014_ila_routed.dcp]

puts "=== WRITE DEBUG PROBES ==="
write_debug_probes -force \
    [file join $outdir retrofpga_t014_ila.ltx]

puts "=== TIMING REPORT ==="
report_timing_summary \
    -file [file join $outdir timing_ila.rpt]

set paths [get_timing_paths -delay_type max -max_paths 1]
if {[llength $paths] == 0} {
    error "No setup timing paths found"
}
set slack [get_property SLACK [lindex $paths 0]]
puts "ILA WORST SETUP SLACK: $slack ns"
if {$slack < 0} {
    error "ILA implementation failed timing"
}

puts "=== WRITE BITSTREAM ==="
write_bitstream -force \
    [file join $outdir retrofpga_t014_ila.bit]

puts "=== PASS: ILA DEBUG BUILD ==="
exit
