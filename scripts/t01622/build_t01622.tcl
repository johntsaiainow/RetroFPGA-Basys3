# T016.22 — SAP-1 IR + CPU State VGA Monitor
# Production top, isolated non-project build.

set root [file normalize [file join [file dirname [info script]] ../..]]
set outdir [file join $root build basys3 t01622]
file mkdir $outdir

set part xc7a35tcpg236-1
set top retrofpga_top

puts "=== T016.22 RTL SOURCES ==="

set sources [list]

foreach dir {rtl rtl/boot rtl/input rtl/video rtl/common cores/sap1} {
    foreach file [glob -nocomplain [file join $root $dir *.sv]] {
        lappend sources $file
    }
}

set sources [lsort -unique $sources]

foreach file $sources {
    puts "RTL: $file"
    read_verilog -sv $file
}

puts "=== T016.22 SYNTHESIS ==="

synth_design -top $top -part $part

puts "=== CONSTRAINTS ==="

read_xdc [file join $root constraints basys3.xdc]
read_xdc [file join $root constraints t016_config_voltage.xdc]

write_checkpoint -force [file join $outdir post_synth.dcp]

report_utilization \
    -file [file join $outdir utilization_synth.rpt]

puts "=== IMPLEMENTATION ==="

opt_design
place_design
phys_opt_design
route_design

write_checkpoint -force [file join $outdir post_route.dcp]

puts "=== REPORTS ==="

report_utilization \
    -file [file join $outdir utilization_route.rpt]

report_timing_summary \
    -file [file join $outdir timing_summary.rpt]

report_drc \
    -file [file join $outdir drc.rpt]

puts "=== TIMING GATE ==="

set paths [get_timing_paths -delay_type max -max_paths 1]

if {[llength $paths] == 0} {
    error "No setup timing paths found"
}

set slack [get_property SLACK [lindex $paths 0]]

puts "T016.22 WORST SETUP SLACK: $slack ns"

if {$slack < 0} {
    error "T016.22 timing failed"
}

puts "=== DRC GATE ==="

set drc_violations [get_drc_violations -quiet]

set drc_blocking 0
set drc_warnings 0

foreach violation $drc_violations {
    set severity [get_property SEVERITY $violation]
    puts "DRC: $violation SEVERITY=$severity"

    switch -nocase -- $severity {
        Error -
        Critical -
        {Critical Warning} {
            incr drc_blocking
        }
        Warning {
            incr drc_warnings
        }
    }
}

puts "DRC BLOCKING: $drc_blocking"
puts "DRC WARNINGS: $drc_warnings"

if {$drc_blocking > 0} {
    error "T016.22 DRC gate failed: $drc_blocking blocking violations"
}

puts "=== DRC GATE PASS ==="

puts "=== BITSTREAM ==="

write_bitstream -force \
    [file join $outdir retrofpga_t01622.bit]

puts "=== T016.22 BUILD PASS ==="
