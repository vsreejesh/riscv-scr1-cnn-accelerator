`timescale 1ns / 1ps

module z3_tb;

  // Inputs
  reg clk = 0;
  reg reset;
  reg start;
  reg signed [31:0] C1_in, C2_in, C3_in, C4_in, C5_in, C6_in, C7_in, C8_in, C9_in, C10_in;

  // Outputs
  wire done;
  wire signed [31:0] C1, C2, C3, C4, C5, C6, C7, C8, C9, C10;

  // Instantiate the Unit Under Test (UUT)
  z3 uut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .C1_in(C1_in),
    .C2_in(C2_in),
    .C3_in(C3_in),
    .C4_in(C4_in),
    .C5_in(C5_in),
    .C6_in(C6_in),
    .C7_in(C7_in),
    .C8_in(C8_in),
    .C9_in(C9_in),
    .C10_in(C10_in),
    .done(done),
    .C1(C1),
    .C2(C2),
    .C3(C3),
    .C4(C4),
    .C5(C5),
    .C6(C6),
    .C7(C7),
    .C8(C8),
    .C9(C9),
    .C10(C10)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    // Initialize Inputs
    reset = 1;
    start = 0;

    C1_in = 32'sd1000;
    C2_in = 32'sd2000;
    C3_in = 32'sd3000;
    C4_in = 32'sd4000;
    C5_in = 32'sd5000;
    C6_in = 32'sd6000;
    C7_in = 32'sd7000;
    C8_in = 32'sd8000;
    C9_in = 32'sd9000;
    C10_in = 32'sd10000;

    // Reset pulse
    #10;
    reset = 0;

    // Start signal
    #10;
    start = 1;
    #10;
    start = 0;

    // Wait for computation to finish
    wait (done == 1);

    #10;
    $display("Output C1  = %d", C1);
    $display("Output C2  = %d", C2);
    $display("Output C3  = %d", C3);
    $display("Output C4  = %d", C4);
    $display("Output C5  = %d", C5);
    $display("Output C6  = %d", C6);
    $display("Output C7  = %d", C7);
    $display("Output C8  = %d", C8);
    $display("Output C9  = %d", C9);
    $display("Output C10 = %d", C10);

    #10;
    $finish;
  end

endmodule
