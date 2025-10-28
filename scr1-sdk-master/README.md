# Open-source SDK for SCR1 core

## Repository contents
Folder | Description
------ | -----------
cnn_git         | cnn accelerator
fpga            | Submodule with SCR1 SDK FPGA projects
scr1            | Submodule with SCR1 core source files
sw              | Software projects for SDK
README.md       | This file


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
```c
#define PLF_CNN_ACCEL_BASE        0x00030000
#define PLF_CNN_CTRL_REG          (*(volatile uint32_t*)(PLF_CNN_ACCEL_BASE + 0x000))
#define PLF_CNN_STATUS_REG        (*(volatile uint32_t*)(PLF_CNN_ACCEL_BASE + 0x004))
#define PLF_CNN_BRAM_BASE         ((volatile uint32_t*)(PLF_CNN_ACCEL_BASE + 0x800))
#define PLF_CNN_STATUS_DONE_BIT   (1 << 4)
#define PLF_CNN_STATUS_RESULT_MSK 0x0F
#define PLF_CNN_IMG_BUF_ADDR      0x00100000


