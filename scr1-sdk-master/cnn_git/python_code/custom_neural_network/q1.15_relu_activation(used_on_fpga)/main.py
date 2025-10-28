import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def relu(z):
    return np.maximum(0, z)

def softmax(z):
    z -= np.max(z, axis=0, keepdims=True)
    exp_z = np.exp(z)
    return exp_z / np.sum(exp_z, axis=0, keepdims=True)

def float_to_q15(arr):
    return np.round(arr * (2 ** 15)).astype(np.int16)


def write_coe_file(filename, data, radix=16):
    with open(filename, "w") as f:
        f.write(f"memory_initialization_radix={radix};\n")
        f.write("memory_initialization_vector=\n")

        for i, val in enumerate(data):
            # Convert signed 16-bit int to unsigned 16-bit hex
            if radix == 16:
                val_str = f"{val & 0xFFFF:04X}"  # 2's complement, padded hex
            else:
                val_str = str(val & 0xFFFF)  # Decimal as unsigned

            if i < len(data) - 1:
                f.write(f"{val_str},\n")
            else:
                f.write(f"{val_str};\n")

def relu_derivative(x):
    return (x > 0).astype(float)

def load_data():
    # Load CSV
    df = pd.read_csv("mnist_data/train.csv")

    # Convert to numpy array - array is m x 785 with first column being the label
    df = np.array(df)

    # We want to use 80% of csv as training data and 20% as testing and m is the number of samples
    m  = df.shape[0]
    m = int(0.8*m)
    train = df[:m]
    test = df[m:]

    # Break the array into labels and pixels - labels is the first column and pixels is everything else
    # Labels becomes [m,1] and pixels become [m,784]
    labels = train[:,0]
    pixels = train[:,1:]

    # Normalize pixel values
    pixels = pixels / 255.0

    # Transpose pixels to shape (784, m) to aid with calculations
    a0 = pixels.T
    n = a0.shape[0]

    # One-hot encode labels
    y = np.zeros((10, m))
    for i in range(m):
        y[labels[i], i] = 1               # Set 1 at correct digit index

    return a0, y, m , n

# Assign random values to weights and biases
# We want small weights initially to avoid early saturation
def initialize_parameters(n):
    w1 = np.random.rand(10,n) * 0.01
    w2 = np.random.rand(10,10) * 0.01
    w3 = np.random.rand(10,10) * 0.01
    b1 = np.random.rand(10,1)
    b2 = np.random.rand(10,1)
    b3 = np.random.rand(10,1)
    return w1, w2, w3, b1, b2, b3

# Forward Propagation
def forward_prop(a0, w1, w2, w3, b1, b2, b3):
    z1 = w1 @ a0 + b1
    a1 = relu(z1)

    z2 = w2 @ a1 + b2
    a2 = relu(z2)

    z3 = w3 @ a2 + b3
    a3 = softmax(z3)
    return a1, a2, a3, z1, z2

# Back propagation
def back_prop(a0, a1, a2, a3, w1, w2, w3, b1, b2, b3, z1, z2, y, m, learning_rate):
    dz3 = a3 - y
    dw3 = 1/m * ( dz3 @ a2.T )
    db3 = 1/m * np.sum( dz3, axis = 1, keepdims = True)

    dz2 = (w3.T @ dz3) * relu_derivative(z2)
    dw2 = 1/m * (dz2  @ a1.T)
    db2 = 1/m * np.sum(dz2, axis = 1, keepdims = True)

    dz1 = (w2.T @ dz2) * relu_derivative(z1)
    dw1 = 1/m * (dz1 @ a0.T)
    db1 = 1/m * np.sum(dz1, axis = 1, keepdims = True)

    # Updating Parameters

    w1 = w1 - learning_rate * dw1
    b1 = b1 - learning_rate * db1
    w2 = w2 - learning_rate * dw2
    b2 = b2 - learning_rate * db2
    w3 = w3 - learning_rate * dw3
    b3 = b3 - learning_rate * db3

    return w1, w2, w3, b1, b2 , b3

def compute_accuracy(a0, w1, w2, w3, b1, b2, b3, y):
    a1, a2, a3 , z1, z2 = forward_prop(a0, w1, w2, w3, b1, b2, b3)
    predictions = np.argmax(a3, axis=0)
    labels = np.argmax(y, axis=0)
    accuracy = np.mean(predictions == labels) * 100
    print(f"Test Accuracy: {accuracy:.2f}%")

def train(a0, y, m, n, t, learning_rate):
    w1, w2, w3, b1, b2, b3 = initialize_parameters(n)
    for i in range(t):
        a1, a2, a3, z1, z2 = forward_prop(a0, w1, w2, w3, b1, b2, b3)
        w1 , w2 , w3, b1, b2, b3 = back_prop(a0, a1, a2, a3, w1, w2, w3, b1, b2, b3, z1, z2, y, m, learning_rate)
        if i%100 == 0:
            compute_accuracy(a0, w1, w2, w3, b1, b2, b3, y)
    return w1, w2, w3, b1, b2, b3

if __name__ == "__main__":
    a0, y, m, n = load_data()
    w1,w2,w3,b1,b2,b3 = train(a0, y, m, n , 5000, 0.1)
    # Export w1 (10x784)
    for i in range(w1.shape[0]):
        write_coe_file(f"w1_row_{i+1}.coe", float_to_q15(w1[i]))

    # Export w2 (10x10)
    for i in range(w2.shape[0]):
        write_coe_file(f"w2_row_{i+1}.coe", float_to_q15(w2[i]))

    # Export w3 (10x10)
    for i in range(w3.shape[0]):
        write_coe_file(f"w3_row_{i+1}.coe", float_to_q15(w3[i]))

    # Export b1, b2, b3 (10x1)
    write_coe_file("b1.coe", float_to_q15(b1.flatten()))
    write_coe_file("b2.coe", float_to_q15(b2.flatten()))
    write_coe_file("b3.coe", float_to_q15(b3.flatten()))

    pass