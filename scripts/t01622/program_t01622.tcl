# T016.22 Phase 5 — Basys 3 Hardware Programming

set root [file normalize \
    [file join [file dirname [info script]] ../..]]

set bitfile [file join \
    $root build basys3 t01622 retrofpga_t01622.bit]

set expected_sha256 \
    50e370428632d2333f6d2c7f30ea82dba1705f7fde6a0c8392a0cca2d4298c44

if {![file exists $bitfile]} {
    error "Bitstream not found: $bitfile"
}

set actual_sha256 [lindex [exec sha256sum $bitfile] 0]

if {$actual_sha256 ne $expected_sha256} {
    error "Bitstream SHA256 mismatch: $actual_sha256"
}

puts "=== T016.22 BITSTREAM VERIFIED ==="
puts "BITSTREAM: $bitfile"
puts "SHA256: $actual_sha256"

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

# Production build has no matching ILA probes.
set_property PROBES.FILE {} $device

puts "=== PROGRAMMING T016.22 ==="

program_hw_devices $device
refresh_hw_device $device

puts "=== PASS: T016.22 FPGA PROGRAMMING ==="

close_hw_manager
exit
