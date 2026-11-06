# RetroFPGA Tutorial 009
# Vivado non-project batch build.

set root [file normalize [file join [file dirname [info script]] ..]]
set outdir [file join $root build basys3]
file mkdir $outdir

set part xc7a35tcpg236-1
set top retrofpga_top

set sources [list]
foreach dir {rtl rtl/boot rtl/input rtl/video rtl/common cores/sap1} {
    foreach file [glob -nocomplain \
        [file join $root $dir *.sv]] {
        lappend sources $file
    }
}

set sources [lsort -unique $sources]

if {[llength $sources] == 0} {
    error "No SystemVerilog sources found"
}

puts "=== Reading RTL ==="
foreach file $sources {
    puts "RTL: $file"
    read_verilog -sv $file
}

puts "=== Synthesis ==="
synth_design -top $top -part $part

puts "=== Reading Constraints ==="
read_xdc [file join $root constraints basys3.xdc]
write_checkpoint -force [file join $outdir post_synth.dcp]

report_utilization \
    -file [file join $outdir utilization_synth.rpt]

puts "=== Implementation ==="
opt_design
place_design
phys_opt_design
route_design

write_checkpoint -force [file join $outdir post_route.dcp]

puts "=== Reports ==="
report_utilization \
    -file [file join $outdir utilization_route.rpt]

report_timing_summary \
    -file [file join $outdir timing_summary.rpt]

report_drc \
    -file [file join $outdir drc.rpt]

puts "=== Timing Validation ==="
set setup_paths [get_timing_paths -delay_type max -max_paths 1]

if {[llength $setup_paths] == 0} {
    error "No setup timing paths found; inspect constraints"
}

set worst_slack [get_property SLACK [lindex $setup_paths 0]]
puts "Worst setup slack: $worst_slack ns"

if {$worst_slack < 0} {
    error "Timing failed: negative setup slack"
}

puts "=== Bitstream Generation ==="
write_bitstream -force \
    [file join $outdir retrofpga_basys3.bit]

puts "=== PASS: Vivado Build Completed ==="
