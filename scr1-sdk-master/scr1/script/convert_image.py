import sys
from PIL import Image
import numpy as np
import struct

def q15_from_float(x_float):
    """ Converts normalized float to Q1.15 fixed-point """
    x_clipped = np.clip(x_float, 0.0, 1.0)
    return np.round(x_clipped * (2**15 - 1)).astype(np.int16)

def main():
    if len(sys.argv) != 3:
        print(f"Usage: python {sys.argv[0]} <input_image.png> <output_file.bin>")
        return

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    # Load and process the image
    img = Image.open(input_path).convert("L")
    img = img.resize((28, 28))
    data = np.asarray(img)
    
    # Convert to Q1.15 format, shape (784, 1)
    data_q15 = q15_from_float(data / 255.0).reshape(784, 1)

    # Save as raw binary file
    with open(output_path, "wb") as f:
        for val in data_q15:
            # Pack as little-endian 16-bit signed integer (<h)
            f.write(struct.pack('<h', val.item()))
    
    print(f"Successfully converted '{input_path}' to '{output_path}'.")
    print(f"Total bytes: {784 * 2} (1568 bytes)")

if __name__ == "__main__":
    main()