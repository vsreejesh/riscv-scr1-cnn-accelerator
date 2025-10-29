#  CNN Accelerator + SCR1 RISC-V Integration  
###  Hardware-Accelerated Neural Network Inference

![CNN on SCR1](https://github.com/vsreejesh/riscv-scr1-cnn-accelerator/blob/main/scr1-sdk-master/images/project.gif)  


---

##  Quick Start

1. **Build Project**  
   Run the provided TCL script in Vivado to automatically create and build the project.  

2. **Program FPGA**  
   Generate the bitstream, update memory, and flash the `.mcs` file to your Arty A7-100T board.  

3. **Test Inference**  
   Open Tera Term → Send `image.bin` via XMODEM → View predicted digit on console.  

---

##  Repository Contents

| Folder | Description |
|---------|-------------|
| **cnn_git** | Contains the CNN accelerator Verilog code and coefficient files. You can also use this as a standalone accelerator project. |
| **fpga** | Contains Vivado project files (`.xpr`, `.tcl`) for the Arty A7-100T FPGA implementation. |
| **scr1** | Submodule with SCR1 core source files. |
| **sw** | Software projects for the SCR1 SDK (bootloader, driver, test utilities). |
| **README.md** | This file. |

---

##  FPGA Project Setup (Vivado)

### Requirements
- **Vivado 2022.2 or later**  
- **Xilinx Arty A7-100T FPGA**  
- **RISC-V GCC Toolchain**  
- **Tera Term (or equivalent UART terminal)**  

---

### Step 1 — Run TCL Flow

1. Open **Vivado (2022.2 or above)**.  
2. Navigate to the **TCL Console** (bottom pane).  
3. Change directory to your project path:
   
   ```tcl
   cd D:\GIT\scr1-cnn-accelerator\scr1-sdk-master\fpga\arty\scr1
4.Source the build script.
```tcl
   source arty_scr1.tcl
```
This automates project creation, IP linking, and synthesis setup.
(Takes a few minutes to complete.)

### 2. Generate Bitstream
Once the TCL flow completes:

Run Synthesis → Implementation → Generate Bitstream.

In the synthesis schematic, you can verify that the CNN accelerator module is integrated with the SCR1 RISC-V core.

![cnn on risc v](https://github.com/vsreejesh/riscv-scr1-cnn-accelerator/blob/main/scr1-sdk-master/images/schematic.gif)  
*(cnn accelerator on riscv scr1)*

### 3. Update Memory
After generating the bitstream:

In the same TCL console, run:

```tcl

source mem_update.tcl
```
This updates memory initialization files for the bootloader and CNN accelerator.

4. Program the FPGA
In Vivado, open Hardware Manager → Open Target → Auto Connect.

Choose Open Configure Memory Device.

From the list, select:

```nginx

s25fl128xxxxx00
```
Load the generated .mcs file:

```makefile

D:\scr1-sdk-master\fpga\arty\scr1\arty_scr1\arty_scr1.runs\impl_1\arty_scr1_new.mcs
```
## Running the Bootloader and CNN Test

Open Tera Term and connect to the correct COM port.

Set baud rate = 115200.

Reset the FPGA board — the bootloader interface will appear in Tera Term.

Type:

```nginx
t
```
This command activates the CNN accelerator test mode.

When Tera Term shows the character ‘C’, it’s ready to receive the MNIST image.

Sending the Image via XMODEM
In Tera Term:

```rust

Files → Transfer → XMODEM → Send
```
Select your image.bin file.
The system will automatically perform inference and display the predicted digit.

![Running the Bootloader and CNN Test](https://github.com/vsreejesh/riscv-scr1-cnn-accelerator/blob/main/scr1-sdk-master/images/Teraterm.gif) 

## Creating the MNIST .bin File
To prepare an MNIST handwritten digit file for inference:

Navigate to:

```rust
scr1-cnn-accelerator\scr1-sdk-master\scr1\script
```
Locate the convert_image.py script.

Run it (recommended: Google Colab for easy setup).

#### Choose a 28×28 grayscale MNIST image to convert.

The script will generate an image.bin file in Q1.15 fixed-point format.

#### Download and use this image.bin when transferring via XMODEM.
![Creating the MNIST .bin File](https://github.com/vsreejesh/riscv-scr1-cnn-accelerator/blob/main/scr1-sdk-master/images/image_conversion.gif) 


## Notes
The cnn_git folder can be reused as a standalone accelerator project.

Make sure all .coe coefficient files are properly linked during synthesis.

Ensure Python 3.x and libraries such as numpy and Pillow are installed if running locally.

Project :SCR1 + CNN Accelerator Integration
Platform: Xilinx Arty A7-100T
Languages: Verilog/SystemVerilog, C, Python
Tools: Vivado, RISC-V GCC, Tera Term

