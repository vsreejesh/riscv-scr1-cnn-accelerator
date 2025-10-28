import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageOps
import numpy as np
import serial
import struct

UART_PORT = 'COM7'  # Set to your FPGA COM port
UART_BAUD = 115200

def q15_matmul_q30(a, b):
    # Q1.15 * Q1.15 = Q2.30 → keep result as Q2.30
    return np.matmul(a.astype(np.int64), b.astype(np.int64))

def q15_add_q30(a_q30, b_q15):
    # Convert Q1.15 bias to Q2.30 before adding
    b_q30 = b_q15.astype(np.int64) << 15
    return a_q30 + b_q30

def q30_relu(x_q30):
    # Just zero out negatives, keep Q2.30
    return np.where(x_q30 > 0, x_q30, 0)

def load_q15_weights_and_biases():
    def load(filename, shape):
        with open(filename, "r") as f:
            values = [int(x.strip(), 16) for line in f for x in line.strip().split(",") if x]
        raw = np.array(values, dtype=np.uint16)
        return raw.astype(np.int16).reshape(shape)

    W1 = load("D:/cnn_from_scratch/cnn_git/python_code/GUI/weights_and_biases/w1_q15.txt", (10, 784))
    b1 = load("D:/cnn_from_scratch/cnn_git/python_code/GUI/weights_and_biases/b1_q15.txt", (10, 1))
    W2 = load("D:/cnn_from_scratch/cnn_git/python_code/GUI/weights_and_biases/w2_q15.txt", (10, 10))
    b2 = load("D:/cnn_from_scratch/cnn_git/python_code/GUI/weights_and_biases/b2_q15.txt", (10, 1))
    return W1, b1, W2, b2


def q15_from_float(x_float):
    x_clipped = np.clip(x_float, 0.0, 1.0)  # assuming normalized inputs
    return np.round(x_clipped * (2 ** 15)).astype(np.int16)


def arithmetic_right_shift(val, shift):
    """
    Performs arithmetic right shift on signed 32-bit integers (scalar or array).
    """
    val = val.astype(np.int32)  # ensure 32-bit signed
    return val >> shift  # Python's >> is arithmetic for int32

def predict_q15(x_q15, W1, b1, W2, b2):
    z1_q30 = q15_add_q30(q15_matmul_q30(W1, x_q15), b1)
    a1_q30 = q30_relu(z1_q30)
    z2_q30 = q15_add_q30(q15_matmul_q30(W2, a1_q30.astype(np.int64) >> 15), b2)
    a2_q30 = q30_relu(z2_q30)
    return np.argmax(a2_q30)

def send_q15_data(flat_q15_data):
    try:
        with serial.Serial(UART_PORT, UART_BAUD, timeout=2) as ser:
            for val in flat_q15_data:
                signed_val = np.int16(val).item()
                ser.write(struct.pack('<h', signed_val))  # Little-endian 16-bit signed
        print("Data sent to FPGA.")
    except serial.SerialException as e:
        print("UART Error:", e)

def load_and_predict():
    filepath = filedialog.askopenfilename()
    if not filepath:
        return

    img = Image.open(filepath).convert("L")
    img = img.resize((28, 28))  # Just in case

    data = np.asarray(img)
    data_q15 = q15_from_float(data / 255.0).reshape(784, 1)

    send_q15_data(data_q15)
    W1, b1, W2, b2 = load_q15_weights_and_biases()
    pred = predict_q15(data_q15, W1, b1, W2, b2)
    print(f"Predicted Digit: {pred}")


# Tiny GUI to open image
root = tk.Tk()
root.withdraw()  # Hide main window
load_and_predict()
