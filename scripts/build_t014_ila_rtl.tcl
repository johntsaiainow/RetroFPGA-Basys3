# Tutorial 014 - RTL-instantiated ILA build.
# Independent from production build.

set root [file normalize [file join [file dirname [info script]] ..]]
set outdir [file join $root build basys3 ila rtl_build]
file mkdir $outdir

set part xc7a35tcpg236-1
set top retrofpga_top_ila

create_project t014_ila_rtl \
    [file join $outdir project] \
    -part $part \
    -force

puts "=== CREATE ILA IP ==="

create_ip \
    -name ila \
    -vendor xilinx.com \
    -library ip \
    -version 6.2 \
    -module_name ila_t014

set ila [get_ips ila_t014]

set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {5} \
    CONFIG.C_DATA_DEPTH {1024} \
    CONFIG.C_PROBE0_WIDTH {2} \
    CONFIG.C_PROBE1_WIDTH {2} \
    CONFIG.C_PROBE2_WIDTH {2} \
    CONFIG.C_PROBE3_WIDTH {8} \
    CONFIG.C_PROBE4_WIDTH {32} \
] $ila

generate_target all $ila


puts "=== ADD PROJECT RTL SOURCES ==="

set sources [list]

foreach dir {rtl rtl/boot rtl/input rtl/video rtl/common cores/sap1} {
    foreach file [glob -nocomplain [file join $root $dir *.sv]] {
        if {[file tail $file] eq "retrofpga_top.sv"} {
            continue
        }
        lappend sources $file
    }
}

lappend sources [file join $root rtl debug retrofpga_top_ila.sv]

add_files -fileset sources_1 [lsort -unique $sources]

set_property file_type SystemVerilog     [get_files -of_objects [get_filesets sources_1] -filter {NAME =~ *.sv}]

set_property top $top [get_filesets sources_1]

add_files -fileset constrs_1     [file join $root constraints basys3.xdc]

update_compile_order -fileset sources_1

puts "=== IP STATUS ==="
report_ip_status

puts "=== LAUNCH SYNTHESIS ==="
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "SYNTH STATUS: $synth_status"

if {![string match "*Complete*" $synth_status]} {
    error "Synthesis failed: $synth_status"
}

puts "=== LAUNCH IMPLEMENTATION ==="
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "IMPLEMENTATION STATUS: $impl_status"

if {![string match "*Complete*" $impl_status]} {
    error "Implementation failed: $impl_status"
}

puts "=== OPEN IMPLEMENTED DESIGN ==="
open_run impl_1

set paths [get_timing_paths -delay_type max -max_paths 1]
if {[llength $paths] == 0} {
    error "No setup timing paths found"
}

set slack [get_property SLACK [lindex $paths 0]]
puts "ILA WORST SETUP SLACK: $slack ns"

if {$slack < 0} {
    error "ILA timing failed"
}

report_timing_summary -file [file join $outdir timing.rpt]

puts "=== COPY DEBUG ARTIFACTS ==="

set run_dir [get_property DIRECTORY [get_runs impl_1]]

set bitfiles [glob -nocomplain [file join $run_dir *.bit]]
set ltxfiles [glob -nocomplain [file join $run_dir *.ltx]]

if {[llength $bitfiles] != 1} {
    error "Expected one bitstream, found [llength $bitfiles]"
}

set preferred_ltx [file join $run_dir retrofpga_top_ila.ltx]

if {[file exists $preferred_ltx]} {
    set ltxfiles [list $preferred_ltx]
} elseif {[llength $ltxfiles] != 1} {
    error "Ambiguous debug probes files: $ltxfiles"
}

file copy -force [lindex $bitfiles 0]     [file join $outdir retrofpga_t014_ila.bit]

file copy -force [lindex $ltxfiles 0]     [file join $outdir retrofpga_t014_ila.ltx]

puts "=== PASS: RTL ILA PROJECT BUILD ==="

close_project
exit
