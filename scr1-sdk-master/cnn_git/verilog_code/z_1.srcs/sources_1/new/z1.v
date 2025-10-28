// First Layer of Neural Network
// Reads 784 input values 
// Multiplies each input with 10 weight vectors, stored in 10 BRAMs
// Adds bias from BRAM; applies relu activation
// Outputs final result; triggers when complete
`timescale 1ns / 1ps

module z1 (
    input wire clk,                     // Clock signal
    input wire reset,                   // Reset signal
    input wire start,                   // Start signal to begin comp
    input wire signed [15:0] douta_i,   // 16 bit signed value received from BRAM
    output reg ena_i,                   // Read enable for BRAM
    output reg [9:0] addra_i,           // Address of BRAM to read from
    output reg done,                    // Trigger signal when inference is done
    output reg [31:0] C1, C2, C3, C4, C5, C6, C7, C8, C9, C10   // Final 32 bit Q1.15 outputs
);

  // FSM States
  parameter IDLE = 2'b00, LOAD = 2'b01, WAIT = 2'b10, COMPUTE = 2'b11;
  reg [1:0] state;
  
  // BRAM interface signals for input and weights
  reg ena_1, ena_2, ena_3, ena_4, ena_5, ena_6, ena_7, ena_8, ena_9, ena_10;
  reg [9 : 0] addra_1, addra_2, addra_3, addra_4, addra_5, addra_6, addra_7, addra_8, addra_9, addra_10;
  wire signed [15 : 0] douta_1, douta_2, douta_3, douta_4, douta_5, douta_6, douta_7, douta_8, douta_9, douta_10;
  
  // BRAM interface signals for biases 
  reg ena_b1;
  reg [3 : 0] addra_b1; 
  wire signed [15 : 0] douta_b1;

  // Accumulator 
  reg signed [63:0] accum1, accum2, accum3, accum4, accum5, accum6, accum7, accum8, accum9, accum10;
  reg signed [63:0] c1_q30, c2_q30, c3_q30, c4_q30, c5_q30, c6_q30, c7_q30, c8_q30, c9_q30, c10_q30;

  // Counter and initial check
  reg [9:0] count;
  reg [4:0] bias_count;
  
  // input buffer
  reg signed [31:0] input_value;
  
  // BRAM Instances
  blk_mem_gen_0 BRAM_1(
  .clka(clk),       // input wire clka
  .ena(ena_1),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_1),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_1)   // output wire [17 : 0] douta
);

  blk_mem_gen_1 BRAM_2(
  .clka(clk),       // input wire clka
  .ena(ena_2),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_2),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_2)   // output wire [17 : 0] douta
);

  blk_mem_gen_2 BRAM_3(
  .clka(clk),       // input wire clka
  .ena(ena_3),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_3),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_3)   // output wire [17 : 0] douta
);

  blk_mem_gen_3 BRAM_4(
  .clka(clk),       // input wire clka
  .ena(ena_4),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_4),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_4)   // output wire [17 : 0] douta
);

  blk_mem_gen_4 BRAM_5(
  .clka(clk),       // input wire clka
  .ena(ena_5),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_5),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_5)   // output wire [17 : 0] douta
);

  blk_mem_gen_5 BRAM_6(
  .clka(clk),       // input wire clka
  .ena(ena_6),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_6),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_6)   // output wire [17 : 0] douta
);

  blk_mem_gen_6 BRAM_7(
  .clka(clk),       // input wire clka
  .ena(ena_7),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_7),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_7)   // output wire [17 : 0] douta
);

  blk_mem_gen_7 BRAM_8(
  .clka(clk),       // input wire clka
  .ena(ena_8),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_8),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_8)   // output wire [17 : 0] douta
);

  blk_mem_gen_8 BRAM_9(
  .clka(clk),       // input wire clka
  .ena(ena_9),      // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_9),  // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_9)   // output wire [17 : 0] douta
);

  blk_mem_gen_9 BRAM_10(
  .clka(clk),       // input wire clka
  .ena(ena_10),     // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_10), // input wire [9 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_10)  // output wire [17 : 0] douta
);

blk_mem_gen_10 BRAM_11 (
  .clka(clk),       // input wire clka
  .ena(ena_b1),     // input wire ena
  .wea(1'b0),       // input wire [0 : 0] wea
  .addra(addra_b1), // input wire [3 : 0] addra
  .dina(18'b0),     // input wire [17 : 0] dina
  .douta(douta_b1)  // output wire [17 : 0] douta
);
  // FSM Logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Reset all registers used and set state to IDLE
      state <= IDLE;
      done  <= 0;
      // Reset BRAM enable and address registers for all 10 BRAMs
      ena_i   <= 0;       addra_i <= 0;
      ena_1   <= 0;       addra_1 <= 0;
      ena_2   <= 0;       addra_2 <= 0;
      ena_3   <= 0;       addra_3 <= 0;
      ena_4   <= 0;       addra_4 <= 0;
      ena_5   <= 0;       addra_5 <= 0;
      ena_6   <= 0;       addra_6 <= 0;
      ena_7   <= 0;       addra_7 <= 0;
      ena_8   <= 0;       addra_8 <= 0;
      ena_9   <= 0;       addra_9 <= 0;
      ena_10  <= 0;      addra_10 <= 0;
      ena_b1  <= 0;      addra_b1 <= 0;
      // Reset Accumulate regs
      accum1  <= 0;
      accum2  <= 0;
      accum3  <= 0;
      accum4  <= 0;
      accum5  <= 0;
      accum6  <= 0;
      accum7  <= 0;
      accum8  <= 0;
      accum9  <= 0;
      accum10 <= 0;
      // Reset Output vectors 
      C1  <= 0;
      C2  <= 0;
      C3  <= 0;
      C4  <= 0;
      C5  <= 0;
      C6  <= 0;
      C7  <= 0;
      C8  <= 0;
      C9  <= 0;
      C10 <= 0;
      // Reset counters
      count       <= 0;
      bias_count  <= 0; 
    end else begin
      case (state)
        // IDLE resets accumulators and waits for start signal
        IDLE: begin
          done        <= 0;
          count       <= 0;
          bias_count  <= 0;
          accum1      <= 0;
          accum2      <= 0;
          accum3      <= 0;
          accum4      <= 0;
          accum5      <= 0;
          accum6      <= 0;
          accum7      <= 0;
          accum8      <= 0;
          accum9      <= 0;
          accum10     <= 0;
          if (start) begin
            // Begin reading input + weights
            state <= LOAD;
            C1 <= 0;
            C2 <= 0;
            C3 <= 0;
            C4 <= 0;
            C5 <= 0;
            C6 <= 0;
            C7 <= 0;
            C8 <= 0;
            C9 <= 0;
            C10 <= 0;
            // BRAM INPUT
            addra_i <= addra_i + 1;
            // Enable BRAM reads
            ena_i <= 1;
            ena_1 <= 1;
            ena_2 <= 1;
            ena_3 <= 1;
            ena_4 <= 1;
            ena_5 <= 1;
            ena_6 <= 1;
            ena_7 <= 1;
            ena_8 <= 1;
            ena_9 <= 1;
            ena_10 <= 1;
            ena_b1 <= 1;
          end
        end
        // Reads input and weights
        LOAD: begin
          // BRAM 1
          addra_1 <= addra_1 + 1;
          // BRAM 2
          addra_2 <= addra_2 + 1;
          // BRAM 3
          addra_3 <= addra_3 + 1;
          // BRAM 4
          addra_4 <= addra_4 + 1;
          // BRAM 5
          addra_5 <= addra_5 + 1;
          // BRAM 6
          addra_6 <= addra_6 + 1;
          // BRAM 7
          addra_7 <= addra_7 + 1;
          // BRAM 8
          addra_8 <= addra_8 + 1;
          // BRAM 9
          addra_9 <= addra_9 + 1;
          // BRAM 10
          addra_10 <= addra_10 + 1;
          // Updates accumulator with input*weights
          accum1  <= accum1 + ($signed(douta_i) * $signed(douta_1));
          accum2  <= accum2 + ($signed(douta_i) * $signed(douta_2));
          accum3  <= accum3 + ($signed(douta_i) * $signed(douta_3));
          accum4  <= accum4 + ($signed(douta_i) * $signed(douta_4));
          accum5  <= accum5 + ($signed(douta_i) * $signed(douta_5));
          accum6  <= accum6 + ($signed(douta_i) * $signed(douta_6));
          accum7  <= accum7 + ($signed(douta_i) * $signed(douta_7));
          accum8  <= accum8 + ($signed(douta_i) * $signed(douta_8));
          accum9  <= accum9 + ($signed(douta_i) * $signed(douta_9));
          accum10 <= accum10 + ($signed(douta_i) * $signed(douta_10));
          // Increments Counter 
          count <= count + 1;
          state <= WAIT;
        end 
        // Used to implement a delay for loading BRAM values as well as a count for
        // loading exactly 784 values from BRAM
        WAIT: begin
            if(count == 785)begin
              // Disables BRAM inputs if 784 values are read
              if(bias_count == 0) begin
                ena_i   <= 0;
                ena_1   <= 0;
                ena_2   <= 0;
                ena_3   <= 0;
                ena_4   <= 0;
                ena_5   <= 0;
                ena_6   <= 0;
                ena_7   <= 0;
                ena_8   <= 0;
                ena_9   <= 0;
                ena_10  <= 0;
              end
              state <= COMPUTE;   
            end else begin
              // BRAM INPUT is incremented
              addra_i <= addra_i + 1;
              state   <= LOAD;
            end
        end
        COMPUTE: begin
          case(bias_count)
            // Add bias to accumulator now and converts Q2.30 to Q1.15 
            1: c1_q30   <= $signed(accum1) + ($signed(douta_b1) <<< 15);
            2: c2_q30   <= $signed(accum2) + ($signed(douta_b1) <<< 15);
            3: c3_q30   <= $signed(accum3) + ($signed(douta_b1) <<< 15);
            4: c4_q30   <= $signed(accum4) + ($signed(douta_b1) <<< 15);
            5: c5_q30   <= $signed(accum5) + ($signed(douta_b1) <<< 15);
            6: c6_q30   <= $signed(accum6) + ($signed(douta_b1) <<< 15);
            7: c7_q30   <= $signed(accum7) + ($signed(douta_b1) <<< 15);
            8: c8_q30   <= $signed(accum8) + ($signed(douta_b1) <<< 15);
            9: c9_q30   <= $signed(accum9) + ($signed(douta_b1) <<< 15);
            10: c10_q30 <= $signed(accum10) + ($signed(douta_b1) <<< 15);
          endcase
           if(bias_count == 11)begin
            // Applies ReLu activation
            C1  <= (c1_q30 < 0)  ? 16'sd0 : ((c1_q30) >> 15);
            C2  <= (c2_q30 < 0)  ? 16'sd0 : ((c2_q30) >> 15);
            C3  <= (c3_q30 < 0)  ? 16'sd0 : ((c3_q30) >> 15);
            C4  <= (c4_q30 < 0)  ? 16'sd0 : ((c4_q30) >> 15);
            C5  <= (c5_q30 < 0)  ? 16'sd0 : ((c5_q30) >> 15);
            C6  <= (c6_q30 < 0)  ? 16'sd0 : ((c6_q30) >> 15);
            C7  <= (c7_q30 < 0)  ? 16'sd0 : ((c7_q30) >> 15);
            C8  <= (c8_q30 < 0)  ? 16'sd0 : ((c8_q30) >> 15);
            C9  <= (c9_q30 < 0)  ? 16'sd0 : ((c9_q30) >> 15);
            C10 <= (c10_q30 < 0) ? 16'sd0 : ((c10_q30) >> 15);
            // Disable BRAM input; trigger done and go back to IDLE state
            ena_b1  <= 0;
            done    <= 1;
            state   <= IDLE;
           end else begin
            bias_count  <= bias_count + 1;
            addra_b1    <= addra_b1 + 1;
            state       <= WAIT ;
          end
        end
      endcase
    end
  end
endmodule