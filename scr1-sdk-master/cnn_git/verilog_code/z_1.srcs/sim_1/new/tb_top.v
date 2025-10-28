`timescale 1ns / 1ps

module tb_top;

  reg clk = 0;
  reg reset = 1;
  reg start = 0;
  reg rx = 1;

  wire done;
  wire [3:0] argmax_index;

  integer i;
  reg signed [15:0] preload_data [0:783];

  // Instantiate DUT
  top uut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .rx(rx),
    .done(done),
    .argmax_index(argmax_index)
  );

  // Clock generation (100MHz)
  always #5 clk = ~clk;

  initial begin
    $display("Starting simulation...");
    $readmemh("input.mem", preload_data);  // preload digit

    #20;
    reset = 0;
    #20;

    // Simulate BRAM loading via Port A (UART-style)
    for (i = 0; i < 784; i = i + 1) begin
      force uut.bram_addr = i;
      force uut.bram_din = preload_data[i];
      force uut.bram_we = 1'b1;
      #10;
      force uut.bram_we = 1'b0;
      #10;
    end

    // Trigger inference
    force uut.inference_start = 1'b1;
    #20;
    force uut.inference_start = 1'b0;

    #50000;
    $display("Done: %b, Prediction: %d", done, argmax_index);
    $finish;
  end

endmodule