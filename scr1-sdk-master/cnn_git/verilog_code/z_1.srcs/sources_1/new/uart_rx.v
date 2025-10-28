// UART Receiver Module
// Takes in the UART RX line and extracts one byte based on UART logic 
module uart_rx #(
    parameter CLK_FREQ = 100_000_000,   // Clock frequency set in the FPGA
    parameter BAUD     = 115200         // UART Baud rate (No. of bits per second transmitted)
)(
    input  wire clk,                    // Clock signal
    input  wire rst,                    // Reset signal
    input  wire rx,                     // UART RX line
    output reg  [7:0] data_out,         // Byte extracted from UART line
    output reg  data_valid              // Goes high if byte extacted successfully
);
    // UART Clock Calculations needed for correct bit extraction
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;      // No. of clock cycles needed to transmit a bit
    localparam HALF_CLKS    = CLKS_PER_BIT / 2;     // Half of clock_cycles per bit (needed as
                                                    // we take the data at middle of 'bit clock cycle')
    // States in UART Byte capture
    localparam IDLE  = 2'd0,    // Waits for falling edge
               START = 2'd1,    // Verifies middle of start bit (makes sure it isnt a false start)
               DATA  = 2'd2,    // Used to shift in the data bits to make a byte
               STOP  = 2'd3;    // Outputs data as a byte
    // Registers required
    reg [1:0] state     = IDLE;     // Store current state; should be IDLE initially
    reg [9:0] clk_count = 0;        // Counts the clock cycles to capture UART based on its baud rate
    reg [2:0] bit_index = 0;        // Used as an array index to shift in the bits to the byte register
    reg [7:0] rx_shift  = 0;        // Byte store register
    reg rx_sync_0       = 1'b1;     // Double sync registers to avoid metastability
    reg rx_sync_1       = 1'b1;  
    wire rx_sync;

    // Double-synchronize RX input to avoid metastability
    always @(posedge clk) begin
        rx_sync_0 <= rx;
        rx_sync_1 <= rx_sync_0;
    end

    assign rx_sync = rx_sync_1; 

    // Logic to capture data based on this double synchronized RX line
    always @(posedge clk or posedge rst) begin
        // Resets all registers involved
        if (rst) begin
            state       <= IDLE;
            clk_count   <= 0;
            bit_index   <= 0;
            data_out    <= 0;
            data_valid  <= 0;
            rx_shift    <= 0;
        end else begin
            // Defaulted to 0 unless we complete reception
            data_valid  <= 0;       

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    // Detect falling edge = start bit
                    if (~rx_sync)       
                        state <= START;
                end

                START: begin
                    // Capture data at the middle of 'bit cycle' so we use HALF_CLKS
                    if (clk_count == HALF_CLKS) begin
                        // Checks if it was a false start bit
                        if (~rx_sync) begin
                            clk_count   <= 0;
                            state       <= DATA;
                        end else
                            state <= IDLE; 
                    end else
                        clk_count <= clk_count + 1;
                end

                DATA: begin
                    // Samples the data at the middle of the 'bit cycle' every bit 
                    // until 8 bits are captured
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count           <= 0;
                        // Bits are shifted into a register with the LSB first
                        rx_shift[bit_index] <= rx_sync;     
                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                    end else
                        clk_count <= clk_count + 1;
                end

                STOP: begin
                    // Wait one bit duration (stop bit) then transfer the full byte into data_out
                    // Go back to IDLE state once done
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        data_out    <= rx_shift;
                        data_valid  <= 1;
                        state       <= IDLE;
                        clk_count   <= 0;
                    end else
                        clk_count <= clk_count + 1;
                end
                // Fault tolerance default if no state matches goto idle
                default: state <= IDLE;
            endcase
        end
    end
endmodule