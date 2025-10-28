# NEURAL NETWORKS

The goal of this project is to understand neural networks at a deeper level. In order to do this, I plan to make a neural network from scratch first in Python, then in Verilog. But before that, I need to understand what a neural network is and the math behind how this network learns.

## FORWARD-FEEDING PART

The smallest component, the building block, of a neural network is a neuron/node. Each of these neurons can be a value between 0 and 1.

For the case of digit recognition, I will be feeding in the MNIST dataset for handwritten digits. Each digit will be a 28 × 28 greyscale image, resulting in 784 pixels. Each of these pixels can be modelled as a neuron, representing the intensity of that pixel, with 0 being black and 1 being white.

So the input layer will have 784 nodes. This will feed into the first section of our “hidden” layer, which will consist of 10 nodes (arbitrary choice), then into a second hidden layer with 10 nodes (again, arbitrary). This finally feeds into the output layer consisting of 10 nodes (representing digits 0–9). The output node with the highest value is the result.

Each connection between neurons has a weight, determining how much a neuron affects the next one. These weights are stored in matrices:

- Input layer: `n[0]` → (784 × 1 matrix)
- Hidden layer 1: `n[1]` → (10 × 1)
- Hidden layer 2: `n[2]` → (10 × 1)
- Output layer: `n[3]` → (10 × 1)

Weights:

- Between input and first layer: `w1` → (784 × 10)
- First and second layer: `w2` → (10 × 10)
- Second layer and output: `w3` → (10 × 10)

We transpose weights and add bias `b` for matrix compatibility. Using a sigmoid activation function:

```
g(x) = 1 / (1 + e^(-x))
```

Final neuron activation formula:

```
n[l] = g(W[l]^T * n[l-1] + b[l])
```

## COST FUNCTION

To train the model, we need to calculate the error using the predicted output and true output. For MNIST, this means comparing predicted digits with actual labels.

We use binary cross-entropy loss for a single node:

```
e = -(y * log(ŷ) + (1 - y) * log(1 - ŷ))
cost = (1/m) * Σ e[n]
```

## BACKPROPAGATION

To minimize the cost, we compute how each weight and bias affects it using partial derivatives. This allows us to adjust parameters to reduce the error:

```
cost = (1/m) * Σ [-(y * log(ŷ) + (1 - y) * log(1 - ŷ))]
ŷ = g(W[l]^T * n[l-1] + b[l])
∂C/∂w = ∂C/∂ŷ * ∂ŷ/∂w
```