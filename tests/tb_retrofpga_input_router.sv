`timescale 1ns/1ps

module tb_retrofpga_input_router;

    logic menu_active = 1;
    logic up_pressed = 0;
    logic down_pressed = 0;
    logic select_pressed = 0;
    logic back_pressed = 0;

    logic menu_up, menu_down, menu_select, menu_back;
    logic cpu_run, cpu_pause, cpu_step;

    retrofpga_input_router dut (.*);

    initial begin
        #1;

        up_pressed = 1;
        #1;

        if (!menu_up || cpu_run)
            $fatal(1, "MENU UP routing failed");

        up_pressed = 0;
        select_pressed = 1;
        #1;

        if (!menu_select || cpu_step)
            $fatal(1, "MENU SELECT routing failed");

        select_pressed = 0;
        menu_active = 0;
        up_pressed = 1;
        #1;

        if (!cpu_run || menu_up)
            $fatal(1, "CPU RUN routing failed");

        up_pressed = 0;
        down_pressed = 1;
        #1;

        if (!cpu_pause || menu_down)
            $fatal(1, "CPU PAUSE routing failed");

        down_pressed = 0;
        select_pressed = 1;
        #1;

        if (!cpu_step || menu_select)
            $fatal(1, "CPU STEP routing failed");

        select_pressed = 0;
        back_pressed = 1;
        #1;

        if (!menu_back || cpu_run || cpu_pause || cpu_step)
            $fatal(1, "CPU BACK routing failed");

        $display("PASS: MENU controls");
        $display("PASS: CPU RUN / PAUSE / STEP");
        $display("PASS: BACK routing");
        $display("=== TUTORIAL 012 INPUT ROUTER PASS ===");

        $finish;
    end

endmodule
