# Tutorial 014 - ILA Probe Discovery
# Non-project mode. Does not modify the production build.

set root [file normalize [file join [file dirname [info script]] ..]]
set outdir [file join $root build basys3 ila]
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
    error "No RTL sources found"
}

puts "=== READING RTL ==="

foreach file $sources {
    read_verilog -sv $file
}

puts "=== SYNTHESIS ==="

synth_design -top $top -part $part

puts "=== READING XDC ==="

read_xdc [file join $root constraints basys3.xdc]

puts "=== SAVING DEBUG SYNTHESIS ==="

write_checkpoint -force \
    [file join $outdir t014_ila_synth.dcp]

puts "=== DISCOVERING DEBUG NETS ==="

set patterns {
    *btn_reset*
    *reset_sync*
    *ps2_clk*
    *ps2_data*
    *keyboard_accepted_edge*
    *keyboard_scan_valid*
    *keyboard_scan_code*
    *ps2_raw_edges*
    *ps2_valid_frames*
}

set report [open \
    [file join $outdir probe_discovery.txt] w]

foreach pattern $patterns {
    puts "=== $pattern ==="
    puts $report "=== $pattern ==="

    set nets [get_nets -quiet -hierarchical \
        -filter "NAME =~ $pattern"]

    puts "MATCHES: [llength $nets]"
    puts $report "MATCHES: [llength $nets]"

    foreach net $nets {
        puts "NET: $net"
        puts $report "NET: $net"
    }
}

close $report

puts "=== DISCOVERY COMPLETE ==="
exit
