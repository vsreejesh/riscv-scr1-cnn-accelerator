# FPGA Neural Network Hardware Accelerator
This project implements a **fully custom, hardware-accelerated digit classifier** based on the MNIST dataset using a **custom neural network ** deployed on an FPGA. It includes:

- Fixed-point Q1.15/Q2.30 inference implementation
- Real-time digit recognition from actual MNIST images


## Table of Contents

- [Project Overview](#project-overview)
- [Technologies Used](#technologies-used)
- [How It Works](#how-it-works)
- [License](#license)

## Project Overview

This project was started to help me understand neural networks and develop my hardware skills. It is built to demonstrate:

- A two-layer neural network (784 → 10 → 10)
- Trained in Python on MNIST and quantized to Q1.15
- Deployed as a **Verilog-based inference core on FPGA**
- Communicates with via UART of risc v scr1 soft core.

The user can drop a **real 28×28 MNIST image in bin format via xmodem of scr1**, and the system will send it to the FPGA, which performs inference and returns the predicted digit.


## Technologies Used

| Layer | Tool |
|:------|:-----|
| Quantization | Q1.15 fixed-point math |
| Hardware Implementation | Verilog (on Xilinx Arty A7) |
| Dataset | MNIST (converted to PNG format) |


## How It Works

1. user convert the image into bin format using the provided python script(riscv_image_conv.ipynb)
2. FPGA receives input, performs:
   - Layer 1: Q1.15 × Q1.15 → Q2.30 → ReLU
   - Layer 2: Q1.15 × Q1.15 → Q2.30 → ReLU
4. Final result (argmax of 10 outputs) gives predicted digit.
  

## License
This project is licensed under the **MIT License**.

Portions of this work are derived from open-source Verilog modules originally developed by r4hulrr (MIT License), specifically the files z1.v, z2.v, and top.v.
These components have been adapted and integrated with a custom wrapper module compliant with the SCR1 memory interface (scr1_memif) protocol, along with architectural modifications to the SCR1 data memory router (scr1_dmem_router) and top-level AHB interconnect (scr1_top_ahb) to support enhanced accelerator connectivity.

