`timescale 1ns/1ps


module tb_button_debounce;

initial begin
    $dumpfile("button_debounce.vcd");
    $dumpvars(0, tb_button_debounce);
end

localparam int unsigned TEST_CLK_HZ = 1000;
localparam int unsigned TEST_DEBOUNCE_MS = 5;

logic clk = 1'b0;
logic rst = 1'b1;
logic button_in = 1'b0;

logic level;
logic pressed;
logic released;

int tests = 0;
int press_count = 0;
int release_count = 0;

// 10 ns simulation clock period.
// Parameterized debounce counts cycles, not
// the actual simulation clock frequency.
always #5 clk = ~clk;

button_debounce #(
.CLK_FREQ_HZ(TEST_CLK_HZ),
.DEBOUNCE_MS(TEST_DEBOUNCE_MS)
) dut (
.clk(clk),
.rst(rst),
.button_in(button_in),
.level(level),
.pressed(pressed),
.released(released)
);

// Count events and ensure pulses do not overlap.
always @(negedge clk) begin
if (!rst) begin
if (pressed && released)
$fatal(1, "Both pulses asserted");

if (pressed && !level)
$fatal(1, "Pressed pulse without high level");

if (released && level)
$fatal(1, "Released pulse without low level");

if (pressed)
press_count++;

if (released)
release_count++;
end
end

// Drive input away from the rising clock edge.
task automatic drive_button(input logic value);
@(negedge clk);
button_in = value;
endtask

task automatic wait_cycles(input int count);
repeat (count)
@(negedge clk);
endtask

task automatic check_state(
input logic expected_level,
input int expected_presses,
input int expected_releases
);
#1;

if (level !== expected_level)
$fatal(1,
"Level mismatch: got=%b expected=%b",
level, expected_level
);

if (press_count != expected_presses)
$fatal(1,
"Press count mismatch: got=%0d expected=%0d",
press_count, expected_presses
);

if (release_count != expected_releases)
$fatal(1,
"Release count mismatch: got=%0d expected=%0d",
release_count, expected_releases
);

tests++;
endtask

initial begin
$display("RetroFPGA Tutorial 006");
$display("Button Debounce Test");

// -------------------------------------------------
// Test 1: Reset
// -------------------------------------------------
wait_cycles(3);
rst = 1'b0;

wait_cycles(2);
check_state(1'b0, 0, 0);

// -------------------------------------------------
// Test 2: Short high pulse must be rejected.
// -------------------------------------------------
drive_button(1'b1);
wait_cycles(2);

drive_button(1'b0);
wait_cycles(8);

check_state(1'b0, 0, 0);

// -------------------------------------------------
// Test 3: Bouncing press.
// -------------------------------------------------
drive_button(1'b1);
wait_cycles(2);

drive_button(1'b0);
wait_cycles(2);

drive_button(1'b1);
wait_cycles(10);

check_state(1'b1, 1, 0);

// -------------------------------------------------
// Test 4: Long hold produces no extra presses.
// -------------------------------------------------
wait_cycles(20);
check_state(1'b1, 1, 0);

// -------------------------------------------------
// Test 5: Short low glitch must be rejected.
// -------------------------------------------------
drive_button(1'b0);
wait_cycles(2);

drive_button(1'b1);
wait_cycles(8);

check_state(1'b1, 1, 0);

// -------------------------------------------------
// Test 6: Bouncing release.
// -------------------------------------------------
drive_button(1'b0);
wait_cycles(2);

drive_button(1'b1);
wait_cycles(2);

drive_button(1'b0);
wait_cycles(10);

check_state(1'b0, 1, 1);

// -------------------------------------------------
// Test 7: Remain released.
// -------------------------------------------------
wait_cycles(20);
check_state(1'b0, 1, 1);

// -------------------------------------------------
// Test 8: Second clean press.
// -------------------------------------------------
drive_button(1'b1);
wait_cycles(10);

check_state(1'b1, 2, 1);

// -------------------------------------------------
// Test 9: Second clean release.
// -------------------------------------------------
drive_button(1'b0);
wait_cycles(10);

check_state(1'b0, 2, 2);

// -------------------------------------------------
// Test 10: Final idle state.
// -------------------------------------------------
wait_cycles(10);
check_state(1'b0, 2, 2);

$display("PASS: Button Debounce verified");
$display("Tests passed: %0d", tests);
$display("Press events: %0d", press_count);
$display("Release events: %0d", release_count);

$finish;
end

initial begin
#100000;

$fatal(1, "Simulation timeout");
end

endmodule
