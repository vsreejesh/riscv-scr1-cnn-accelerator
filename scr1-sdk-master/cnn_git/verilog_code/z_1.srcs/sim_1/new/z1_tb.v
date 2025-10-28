`timescale 1ns / 1ps

module z1_tb;

  // Inputs
  reg clk;
  reg reset;
  reg start;

  // Outputs (Fixed widths)
  wire done;
  wire signed [15:0] C1, C2, C3, C4, C5, C6, C7, C8, C9, C10;

  // Instantiate the Unit Under Test (UUT)
  z1 uut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .done(done),
    .C1(C1), .C2(C2), .C3(C3), .C4(C4), .C5(C5),
    .C6(C6), .C7(C7), .C8(C8), .C9(C9), .C10(C10)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 10ns period

  initial begin
    // Initialize Inputs
    reset = 1;
    start = 0;

    // Wait for global reset
    #20;
    reset = 0;

    // Start the computation
    #20;
    start = 1;
    #10;
    start = 0;

    // Wait until done is high
    wait (done);

    // Display outputs
    $display("\nLayer 1 Outputs (Q1.15 ReLU Applied):");
    $display("C1  = %d", C1);
    $display("C2  = %d", C2);
    $display("C3  = %d", C3);
    $display("C4  = %d", C4);
    $display("C5  = %d", C5);
    $display("C6  = %d", C6);
    $display("C7  = %d", C7);
    $display("C8  = %d", C8);
    $display("C9  = %d", C9);
    $display("C10 = %d", C10);

    // End simulation
    #100;
    $finish;
  end

endmodule
