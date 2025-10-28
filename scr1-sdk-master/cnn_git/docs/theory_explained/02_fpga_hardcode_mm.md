
# FPGA NN

Now is the fun part – implementing it on the FPGA. I will be using Verilog for this and before we start this, let's look at what we’ve done already:

1. The math behind Neural Networks  
2. The Python code to generate the necessary weights and biases for our NN layers

The main task for the FPGA is to take these weights and biases from our Python code and apply it to our samples. We use an FPGA here instead of direct Python code simply because an FPGA is faster. But instead on directly moving onto this daunting task, lets start with a much smaller matrix, which we will hardcode for ease of understanding.

---

# Implementing Basic Matrix Multiply

We’re going to implement a basic 2x2 matrix multiplication first so let’s understand the math behind it.

Let’s say:

**Matrix A (2×2):**

```
A = [
  [a00, a01],
  [a10, a11]
]

B = [
  [b00, b01],
  [b10, b11]
]

C = [
  [c00, c01],
  [c10, c11]
]
```

Each value of `C` is computed as a **dot product** of a row from A and a column from B.


```python
# Calculate C00
C[0][0] = A[0][0] * B[0][0] + A[0][1] * B[1][0]  # 1*5 + 2*7 = 19

# Calculate C01
C[0][1] = A[0][0] * B[0][1] + A[0][1] * B[1][1]  # 1*6 + 2*8 = 22

# Calculate C10
C[1][0] = A[1][0] * B[0][0] + A[1][1] * B[1][0]  # 3*5 + 4*7 = 43

# Calculate C11
C[1][1] = A[1][0] * B[0][1] + A[1][1] * B[1][1]  # 3*6 + 4*8 = 50
```

---

### Hardcoded Version 

```verilog
// Matrix A
a00 = 1; a01 = 2;
a10 = 3; a11 = 4;

// Matrix B
b00 = 5; b01 = 6;
b10 = 7; b11 = 8;
```

---

### Block Diagram for 2x2 Matrix Multiply

**Objective:**  
We want to compute `C = A × B`, where:

- A is a 2x2 matrix with hardcoded values  
- B is a 2x2 matrix with hardcoded values  
- C is the output 2x2 matrix  

**Modules in the Block Diagram:**

- Inputs: `clk`, `reset`
- FSM Control: controls timing (when to multiply/add)
- Registers: store matrices A & B
- Logic: `A[i][k] * B[k][j]`
- Result Register: stores final result matrix C

---

### FSM (Finite State Machine)

| State    | Description                        |
|----------|------------------------------------|
| IDLE     | Wait for `start` signal            |
| LOAD     | Load/initialize matrix values      |
| COMPUTE  | Do multiply-accumulate operations  |
| DONE     | Signal that matrix C is ready      |

**FSM Flow Diagram (Text Representation):**

```
+--------+     +--------+     +--------+
|  IDLE  | --> |  LOAD  | --> |  DONE  |
+--------+     +--------+     +--------+
     |              |
     v              |
  +--------+        |
  | COMPUTE| <------+
  +--------+
```

---

### Verilog Implementation Steps

**1. Module Declaration**
```verilog
module matrix_mul_2x2(
  input wire clk,
  input wire reset,
  input wire start,
  output reg done,
  output reg [15:0] C00, C01, C10, C11
);
```

**2. State + Register Declarations**
```verilog
parameter IDLE = 2'b00, LOAD = 2'b01, COMPUTE = 2'b10, DONE = 2'b11;
reg [1:0] state;

// Matrix A
reg [7:0] A00 = 8'd1, A01 = 8'd2;
reg [7:0] A10 = 8'd3, A11 = 8'd4;

// Matrix B
reg [7:0] B00 = 8'd5, B01 = 8'd6;
reg [7:0] B10 = 8'd7, B11 = 8'd8;

// Temporary results
reg [15:0] tempC00, tempC01, tempC10, tempC11;
```

**3. FSM Logic**
```verilog
always @(posedge clk or posedge reset) begin
  if (reset) begin
    state <= IDLE;
    done <= 0;
  end else begin
    case (state)
      IDLE: begin
        done <= 0;
        if (start)
          state <= LOAD;
      end
      LOAD: begin
        // no-op for now
        state <= COMPUTE;
      end
      COMPUTE: begin
        tempC00 <= A00 * B00 + A01 * B10;
        tempC01 <= A00 * B01 + A01 * B11;
        tempC10 <= A10 * B00 + A11 * B10;
        tempC11 <= A10 * B01 + A11 * B11;
        state <= DONE;
      end
      DONE: begin
        done <= 1;
        C00 <= tempC00;
        C01 <= tempC01;
        C10 <= tempC10;
        C11 <= tempC11;
        state <= IDLE;
      end
    endcase
  end
end
```
**4. Testbench**

A testbench is then written to verify functionality.
```verilog
'timescale 1ns / 1ps
module tb;

// Testbench signals
reg clk;
reg reset;
reg start;
wire done;
wire [15:0] C00, C01, C10, C11;

// Instantiate the DUT (Device Under Test)
top matrix_mul_2x2(
		.clk(clk),
		.reset(reset),
		.start(start),
		.done(done),
		.C00(C00) , .C01(C01),
		.C10(C10) , .C11(C11)
);

// Clock generation (10 ns period = 100 MHz)
always #5 clk = ~clk;

initial begin

// Initialize inputs
clk = 0;
reset = 1;
start = 0;

// Apply reset for some cycles
#10;
reset = 0;

// Wait a bit, then start
#10;
start = 1;
#10;
start = 0; // Pulse start for 1 cycle

// Wait for computation to finish
wait (done == 1);

// Wait a few cycles for outputs to stabilize
#10;

// Display results
$display("C = [ %0d  %0d ]", C00, C01);
$display("    [ %0d  %0d ]", C10, C11);

// End simulation
$finish;
end
endmodule
```
We get the expected output so now we can move onto a slightly more complex task - getting the matrices from memory 
instead of from registers.