# Hardware Integration: CNN Accelerator + SCR1 RISC-V Processor

## Overview
This project demonstrates the integration of a **custom CNN hardware accelerator (`cnn_core`)** with the **Syntacore SCR1 RISC-V processor** on a **Xilinx Artix-7 FPGA**.  
The integration involved:
- Creating a **SystemVerilog interface wrapper**
- Modifying the **SCR1 data memory router**
- Extending the **SCR1 bootloader** for UART-based testing

The resulting system performs **neural network inference directly in hardware**, with control and monitoring handled by RISC-V software.

---

## Table of Contents
1. [Hardware Integration](#1-hardware-integration)
   - [Interface Wrapper](#interface-wrapper)
   - [SCR1 Core Modifications](#scr1-core-modifications)
   - [Address Map](#address-map)
2. [Software Design (RISC-V Driver)](#2-software-design-risc-v-driver)
   - [Bootloader Modifications](#bootloader-modifications)
   - [Data Preparation (PC Side)](#data-preparation-pc-side)
3. [Implementation & Testing](#3-implementation--testing)
   - [Tools Used](#tools-used)
   - [Build Process](#build-process)
   - [Testing Procedure](#testing-procedure)
   - [Results](#results)
4. [Conclusion](#4-conclusion)
   - [Summary of Work](#summary-of-work)
   - [Challenges and Limitations](#challenges-and-limitations)
   - [Future Work](#future-work)

---

## 1. Hardware Integration

### Interface Wrapper (`cnn_accelerator_memif_wrapper.sv`)
The `cnn_accelerator_memif_wrapper.sv` module bridges the **CNN accelerator core (`cnn_core`)** with the **SCR1 memory system**.

#### Key Functions
- **Protocol Translation**  
  Implements the slave side of the `scr1_memif` protocol (`scr1_memif.svh`), handling memory request and response signals (`port_req`, `port_req_ack`, `port_cmd`, `port_addr`, etc.).

- **Register Mapping**
  - **Control Register (0x000)**  
    Writing bit[0] = 1 starts inference (`cnn_inference_start`).
  - **Status Register (0x004)**  
    Reading returns the accelerator status:  
    - Bit 4 → `cnn_done_out`  
    - Bits [3:0] → `cnn_argmax_index_out`

- **BRAM Interface**  
  Maps the SCR1 memory interface to the accelerator’s BRAM input port for writing input data from the CPU.

- **Response Handling**  
  Implements a 0-wait-state response, acknowledging requests immediately with `SCR1_MEM_RESP_RDY_OK`.

---

### SCR1 Core Modifications

#### `scr1_dmem_router.sv`
- Added **port3** for the accelerator connection.  
- Defined address range: `0x00030000 – 0x0003FFFF`.  
- Updated muxing logic to include port3 request, response, and data lines.

#### `scr1_top_ahb.sv`
- Declared new wires for the CNN interface (`cnn_dmem_req`, `cnn_dmem_req_ack`, etc.).  
- Connected port3 signals to the wrapper.  
- Instantiated the wrapper (`cnn_wrapper_inst`), connecting it to the system clock (`clk`) and local reset (`core_rst_n_local`).  
- Routed wrapper LED output to `leds_o`.

---

### Address Map

| Address Range     | Description          | Access | Size  | Notes |
|-------------------|---------------------|---------|-------|-------|
| 0x00030000        | CNN Accelerator Base | - | 64 KB | Port 3 Mapping |
| 0x00030000        | Control Register     | Write | 4 B | Bit 0: Start Inference |
| 0x00030004        | Status Register      | Read | 4 B | Bit 4: Done, Bits [3:0]: Result |
| 0x00030800–0x00030FFF | Input Image BRAM | Write | 2 KB | 1024 × 16-bit Entries |
| (Others)          | Reserved/Internal | - | - | Weights/Biases via COE |

---

## 2. Software Design (RISC-V Driver)

### Bootloader Modifications (`scbl.c`, `plf_arty_scr1.h`)
Integration was done within the **Syntacore first-stage bootloader (sc-bl)** framework.

#### Platform Definitions (`plf_arty_scr1.h`)
`c
#define PLF_CNN_ACCEL_BASE        0x00030000
#define PLF_CNN_CTRL_REG          (*(volatile uint32_t*)(PLF_CNN_ACCEL_BASE + 0x000))
#define PLF_CNN_STATUS_REG        (*(volatile uint32_t*)(PLF_CNN_ACCEL_BASE + 0x004))
#define PLF_CNN_BRAM_BASE         ((volatile uint32_t*)(PLF_CNN_ACCEL_BASE + 0x800))
#define PLF_CNN_STATUS_DONE_BIT   (1 << 4)
#define PLF_CNN_STATUS_RESULT_MSK 0x0F
#define PLF_CNN_IMG_BUF_ADDR      0x00100000


## 3.New Bootloader Command
A new command t was added to test the accelerator via UART.

## Workflow (cmd_cnn_test):

Receive image.bin via XMODEM → store in DDR (0x00100000).

Copy image to accelerator BRAM.

Write to Control Register → start inference.

Poll Status Register until done.

Read and print 4-bit prediction result to UART.

Data Preparation (PC Side)
A Python preprocessing script converts 28×28 grayscale images into 3136-byte binary files (image.bin).

## Steps:

Convert to grayscale and resize to 28×28.

Convert to Q1.15 fixed-point format.

Pad 16-bit pixel values to 32 bits.

Save as image.bin.

The file is sent via UART (XMODEM) to the RISC-V system for inference.

3. Implementation & Testing
Tools Used
Tool	Purpose
Xilinx Vivado (e.g., 2022.2)	FPGA synthesis, implementation, and bitstream generation
RISC-V GCC Toolchain	Compile modified bootloader
Tera Term / XMODEM Utility	UART communication and image transfer
Python (Pillow, NumPy)	Image preprocessing to binary format

Build Process
Hardware
Add all Verilog/SystemVerilog files to a Vivado project targeting Artix-7 XC7A100T.

Include modified SCR1 modules and constraint files (arty_scr1_physical.xdc, etc.).

Synthesize → Implement → Generate .bit bitstream.

Optionally preload bootloader .mem into FPGA BRAM.

## Software
Compile modified bootloader (scbl.c, plf_arty_scr1.h) using RISC-V GCC.

Generate outputs: scbl.elf, scbl.bin, scbl.mem.

## Testing Procedure
Program FPGA with bitstream.

Load Bootloader via UART/XMODEM (if not preloaded).

Prepare input using Python script → image.bin.

## Run accelerator test:

shell
Copy code
Bootloader> t
Console Output:

arduino
Copy code
Loading image...
Copying to BRAM...
Starting inference...
Inference complete.
Predicted Digit: 2
Verify that the prediction matches the test image.

## Results
Successful integration of CNN accelerator with SCR1 RISC-V.

Correct operation of data transfer, inference, and result reporting.

End-to-end test demonstrated accurate digit recognition (e.g., predicted “2” for input digit ‘2’).

## 4. Conclusion
Summary of Work
Implemented a custom CNN accelerator integrated with SCR1 RISC-V.

Developed a SystemVerilog wrapper for memory bridging.

Extended the SCR1 bootloader to support accelerator testing.

Verified full system functionality on FPGA hardware.

## Challenges and Limitations
Platform-specific interface: SCR1 memif limits portability (not AXI4-Lite compatible).

Manual data preparation: Requires PC-side preprocessing.

Limited CNN architecture: Supports only fully connected layers.

No performance metrics: Latency and power not measured.


Perform power and resource utilization analysis.
