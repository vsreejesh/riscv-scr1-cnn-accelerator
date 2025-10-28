# 3x3 Matrix Multiplication from Memory

Since the end goal is to multiply matrices of sizes up to 10x784, we need to stop using registers as to hold these number of matrices, there would not be enough registers - it is simply not feasible - the FPGA will run out of LUTs/FFs . We will instead use BRAM to store these matrices. We will start with a simple 3x3 matrix multiplication and then build on from there - or at least that was the thinking. This was my thought process:

![image (1)](https://github.com/user-attachments/assets/597a1b50-8228-4205-a978-5820fd68dd6f)


But when I got to this stage, I realized that if I am going to convert this for my MNIST data (which is the end goal), I will be receiving data in a 784 x 1 form from the pixels of a 28x28 image.  Now if I wanted to do this row by row, I would have need 784 dual port BRAMs which my arty a7 100t simply does not have. 

I could be getting it in the form of a 28x28 and using 28 BRAMs and so all data would be loaded in 28 clock cycles but my weights and biases are for a 784x1 input so this would not give me the correct end result. So my conclusion was that I would make a functioning model first and work on pipelining for latency later as shown in my thought process below:

![image (2)](https://github.com/user-attachments/assets/6dc8e019-d9f2-4408-869a-3a5b4db8092c)


So, I will return to pipelining and maybe this 3x3 matrix multiplication again but for now, I will move onto a 3x3 * 3x1 matrix multiplication in order to get my model functioning first.
