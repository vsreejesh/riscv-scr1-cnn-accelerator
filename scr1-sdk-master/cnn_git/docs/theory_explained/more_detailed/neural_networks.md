# What is a Neural Network?

We can think of a neural network as a black box. You feed in a **lot** of samples along with the correct value for each sample into the black box and out comes a system that is able to correctly identify any future samples of the same type. For example, the input could be a bunch of pictures of animals along with the name of each animal and the output would be a system that is able to correctly identify those animals given a new picture (with a chance of error of course).

We will be applying this concept to the fpga board - where we feed in a handwritten digit and we expect the fpga to correctly identify the digit. The real question is how? Well, we can understand this by looking at a structure of a neural network.

<div align="center">
  <img src="https://github.com/user-attachments/assets/f2a8e8cb-f177-4266-b6e3-266aa41dd34b" alt="Jetson_jpeg" width="400"/>
</div>

As we can see above, we have three distinct parts - the input layer, the hidden layer and the output layer. I will be using the concept of mnist digit recognition to explain this, but it can be applied to anything. 

- Input layer - This is what is fed into the neural network. Sure, we feed in the image but in what form? MNIST images are 28x28 greyscale meaning there are 784 pixels. Each of these pixels can have a value of between 0 and 1, depending on the intensity of the pixel - where 0 is completely black and 1 is white. So, we can feed in 784 pixels along with their intensity value into the fpga as this format is easily mathematically understood. Now what happens to these pixels?

- Hidden layer - Each of these pixels can be referred to as a node. 
