set root [file normalize [file join [file dirname [info script]] ..]]
set bitfile [file join $root build basys3 retrofpga_basys3.bit]

if {![file exists $bitfile]} {
    error "Bitstream not found: $bitfile"
}

open_hw_manager
connect_hw_server
open_hw_target

set devices [get_hw_devices -quiet xc7a35t*]

if {[llength $devices] != 1} {
    error "Expected exactly one Basys 3 FPGA; found [llength $devices]"
}

set device [lindex $devices 0]
current_hw_device $device

set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device

puts "=== PASS: Basys 3 JTAG Programming Completed ==="

close_hw_manager
