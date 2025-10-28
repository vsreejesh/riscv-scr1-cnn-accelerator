//
// cnn_accelerator_memif_wrapper.sv
//
// Wrapper for the CNN core, compatible with the scr1_memif protocol.
// Connects to a port (e.g., port2) of scr1_dmem_router.
//
`include "scr1_memif.svh"
`include "scr1_arch_description.svh"

module cnn_accelerator_memif_wrapper (
    input   logic               clk,
    input   logic               rst_n, // Active-low reset

    // Interface from router (connect these to port2_* signals)
    output  logic                           port_req_ack, // We ACK the router's request
    input   logic                           port_req,     // We receive the request from the router
    input   type_scr1_mem_cmd_e             port_cmd,     // We receive the command
    input   type_scr1_mem_width_e           port_width,   // We receive the width
    input   logic [`SCR1_DMEM_AWIDTH-1:0]   port_addr,    // We receive the address
    input   logic [`SCR1_DMEM_DWIDTH-1:0]   port_wdata,   // We receive write data
    output  logic [`SCR1_DMEM_DWIDTH-1:0]   port_rdata,   // We send read data back to the router
    output  type_scr1_mem_resp_e            port_resp,    // We send the response back to the router

    // Output to FPGA LEDs
    output wire [3:0]    leds_o
);

    // --- Core Signals (internal connections to your CNN) ---
    wire        cnn_reset = ~rst_n; // Convert active-low reset to active-high for your core
    wire        cnn_inference_start;
    wire [3:0]  cnn_argmax_index_out;
    wire        cnn_done_out;
    wire [9:0]  cnn_bram_addr_a;
    wire        cnn_bram_we_a;
    wire signed [15:0] cnn_bram_din_a;

    // --- Address Decoding ---
    // The router does not strip the base address, so we must check for it.
    // However, the router only forwards requests in the 0x0002xxxx range to this port.
    // So, we only need to decode the lower bits of the address.
    localparam ADDR_CTRL      = 32'h000;
    localparam ADDR_STATUS    = 32'h004;
    localparam ADDR_BRAM_BASE = 32'h800;
    
    wire        is_write    = (port_cmd == SCR1_MEM_CMD_WR);
    wire        is_read     = (port_cmd == SCR1_MEM_CMD_RD);
    wire [11:0] addr_low    = port_addr[11:0]; 

    // --- Write Logic ---
    reg start_reg;

    wire write_to_ctrl = port_req & is_write & (addr_low == ADDR_CTRL);
    wire write_to_bram = port_req & is_write & (addr_low >= ADDR_BRAM_BASE);
    
    assign cnn_bram_addr_a = port_addr[11:2]; 
    assign cnn_bram_we_a   = write_to_bram;
    assign cnn_bram_din_a  = port_wdata[15:0];
    
    always @(posedge clk or posedge cnn_reset) begin
        if (cnn_reset) begin
            start_reg <= 1'b0;
        end else if (write_to_ctrl) begin
            start_reg <= port_wdata[0];
        end else if (cnn_done_out) begin
            start_reg <= 1'b0; // Auto-clear when done
        end
    end
    
    assign cnn_inference_start = start_reg;

    // --- Read Logic (Combinational) ---
    wire read_from_status = port_req & is_read & (addr_low == ADDR_STATUS);
    
    always @(*) begin
        if (read_from_status) begin
            port_rdata = {27'b0, cnn_done_out, cnn_argmax_index_out};
        end else begin
            port_rdata = 32'h0;
        end
    end

    // --- Response Logic (0-wait-state) ---
    assign port_req_ack = 1'b1; // Always acknowledge immediately
    assign port_resp    = (port_req) ? SCR1_MEM_RESP_RDY_OK : SCR1_MEM_RESP_NOTRDY;

    // --- Instantiate your Verilog CNN Core ---
    cnn_core cnn_inst (
        .clk(clk),
        .reset(cnn_reset),
        
        .bram_addr_a(cnn_bram_addr_a),
        .bram_we_a(cnn_bram_we_a),
        .bram_din_a(cnn_bram_din_a),
        
        .inference_start(cnn_inference_start),
        .argmax_index_out(cnn_argmax_index_out),
        .done_out(cnn_done_out)
    );

    assign leds_o = cnn_argmax_index_out;

endmodule