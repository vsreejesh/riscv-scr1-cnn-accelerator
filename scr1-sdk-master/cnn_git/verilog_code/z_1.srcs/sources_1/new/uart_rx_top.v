// UART Loader
// Loads 1568 bytes or 784 16 bit values via UART into the BRAM
// and triggers when done
module uart_rx_top (
    input  wire clk,                        // Clock signal
    input  wire [4:0] sw,                   // Use sw[0] as active-low reset
    input  wire rx,                         // UART RX Line
    output reg signed [15:0] bram_din,      // 16 bit signed value to be written to BRAM
    output reg [9:0] bram_addr,             // BRAM address to be written to (784 elements)
    output reg bram_we,                     // Write enable signal for BRAM
    output reg inference_start              // Goes high when all 1568 bytes received
);
// Parameters for UART
localparam CLK_FREQ     = 100_000_000;      // Clock frequency FPGA is set to
localparam BAUD         = 115200;           // UARR Baud rate (number of bits sent per second)
localparam TOTAL_BYTES  = 1568;             // Total bytes to be sent (784 16-bit values as 28x28 image)

// Internal UART wires
wire [7:0] rx_data;
wire       rx_valid;

// Internal control signals
reg [10:0] byte_counter = 0;    // 0 to 1568
reg [7:0] lsb_buffer    = 0;
reg byte_phase          = 0;    // 0 = expecting LSB, 1 = expecting MSB

// Reset Handling
wire rst;
assign rst = ~sw[0];            // sw[0] active-low -> active-high reset inside

// Instantiate UART receiver
uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD(BAUD)
) u_uart_rx (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .data_out(rx_data),
    .data_valid(rx_valid)
);

// UART assemble and BRAM load logic
always @(posedge clk) begin
    if (rst) begin
        byte_counter <= 0;
        bram_addr <= 0;
        bram_we <= 0;
        inference_start <= 0;
        byte_phase <= 0;
        lsb_buffer <= 0;
    end else begin
        // Default: no write unless ready
        bram_we <= 0; 
        if (rx_valid) begin
            // Total of 1568 bytes are expected 
            if (byte_counter < TOTAL_BYTES) begin
                byte_counter <= byte_counter + 1;
                if (byte_phase == 0) begin
                    lsb_buffer <= rx_data; // First byte: LSB
                    byte_phase <= 1;
                end else begin
                    // Second byte: MSB, complete 16-bit word
                    // Done this way as we want to store 16 bit words into BRAM
                    bram_din    <= {rx_data, lsb_buffer};   // MSB first
                    bram_we     <= 1;                       // Enable BRAM write
                    bram_addr   <= bram_addr + 1;
                    byte_phase  <= 0;
                end
            end
        end
        // After 1568 bytes are received, interference start is set to high
        if (byte_counter == TOTAL_BYTES) begin
            inference_start <= 1;
        end else begin
            inference_start <= 0;
        end
    end
end
endmodule
