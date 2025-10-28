`timescale 1ns / 1ps

module top_tb;

    // Inputs
    reg clk;
    reg reset;
    reg start;

    // Outputs
    wire done;
    wire [3:0] argmax_index;

    // Instantiate DUT
    top uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done),
        .argmax_index(argmax_index)
    );

    // Clock generation (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initial values
        reset = 1;
        start = 0;

        // Wait a few cycles, then release reset
        #20;
        reset = 0;

        // Start inference
        #20;
        start = 1;
        #10;
        start = 0;

        // Wait for computation to complete
        wait (done);

        // Display result
        $display("? Done! Predicted Class Index: %0d", argmax_index);

        #50;
        $finish;
    end

endmodule
