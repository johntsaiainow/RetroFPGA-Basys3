# T016.21 Phase 5
# Basys 3 Hardware Acceptance
# Reuse the T016.20 hardware-verified bitstream.

set root [file normalize \
    [file join [file dirname [info script]] ../..]]

set bitfile [file join \
    $root build basys3 t01620 retrofpga_t01620.bit]

set probefile [file join \
    $root build basys3 t01620 retrofpga_t01620.ltx]

if {![file exists $bitfile]} {
    error "Bitstream not found: $bitfile"
}

puts "=== T016.21 HARDWARE PROGRAMMING ==="
puts "BITSTREAM: $bitfile"

open_hw_manager
connect_hw_server
open_hw_target

set devices [get_hw_devices -quiet xc7a35t*]

if {[llength $devices] != 1} {
    error "Expected exactly one Basys 3 FPGA; found [llength $devices]"
}

set device [lindex $devices 0]
current_hw_device $device

puts "DEVICE: $device"

set_property PROGRAM.FILE $bitfile $device

# Load matching ILA probes when available.
if {[file exists $probefile]} {
    set_property PROBES.FILE $probefile $device
    puts "PROBES: $probefile"
}

program_hw_devices $device
refresh_hw_device $device

puts "=== PASS: T016.21 FPGA PROGRAMMING ==="

close_hw_manager
exit
