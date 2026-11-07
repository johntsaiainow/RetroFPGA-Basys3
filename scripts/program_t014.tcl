set root [file normalize [file join [file dirname [info script]] ..]]
set bitfile [file join $root build basys3 retrofpga_basys3.bit]

if {![file exists $bitfile]} {
    error "Bitstream not found: $bitfile"
}

open_hw_manager
connect_hw_server
open_hw_target

set device [lindex [get_hw_devices xc7a35t_0] 0]

if {$device eq ""} {
    error "Basys 3 XC7A35T device not found"
}

current_hw_device $device
set_property PROGRAM.FILE $bitfile $device

program_hw_devices $device
refresh_hw_device $device

puts "=== PASS: Tutorial 014 FPGA Programmed ==="

close_hw_manager
