# ---------------------------------------------------------------
# 1. Install necessary library
# ---------------------------------------------------------------
!pip install pillow

import numpy as np
from PIL import Image, ImageOps
from google.colab import files
import struct
import io

# ---------------------------------------------------------------
# 2. Upload your image file
# ---------------------------------------------------------------
print("Please upload your handwritten digit image (JPG, PNG, etc.)...")
uploaded = files.upload()

if not uploaded:
    print("\nNo file uploaded. Please run the cell again.")
else:
    # Get the filename (works with one file)
    input_filename = list(uploaded.keys())[0]

    print(f"\nProcessing '{input_filename}'...")

    # ---------------------------------------------------------------
    # 3. Process the image
    # ---------------------------------------------------------------

    # Open the image from the in-memory bytes
    img = Image.open(io.BytesIO(uploaded[input_filename]))

    # Convert to grayscale ('L' mode)
    img_gray = img.convert('L')

    # Resize to 28x28
    # We use Image.LANCZOS for the best downscaling quality
    img_resized = img_gray.resize((28, 28), Image.LANCZOS)

    # Invert the image
    # MNIST models expect white digits (255) on a black background (0)
    # User-drawn images are usually black digits (0) on white (255)
    img_inverted = ImageOps.invert(img_resized)

    # Convert image to a numpy array (values 0-255)
    pixel_data = np.array(img_inverted)

    # ---------------------------------------------------------------
    # 4. Convert pixels to Q1.15 fixed-point format
    # ---------------------------------------------------------------

    # a. Normalize 0-255 -> 0.0-1.0
    normalized_data = pixel_data / 255.0

    # b. Scale to Q1.15 range (max value is 2^15 - 1 = 32767)
    q15_data = (normalized_data * 32767.0).astype(np.int16)

    # c. Flatten the 28x28 array to a 1D array of 784 numbers
    flat_data = q15_data.flatten()

    # ---------------------------------------------------------------
    # 5. Write the binary file (image.bin)
    # ---------------------------------------------------------------

    output_filename = 'image.bin'

    with open(output_filename, 'wb') as f:
        for pixel in flat_data:
            # This is the most important step.
            # Your C code reads a 32-bit word (uint32_t) for each pixel.
            # Your hardware wrapper uses the lower 16 bits (port_wdata[15:0]).
            #
            # We pack each 16-bit pixel ('h') with 2 bytes of
            # zero-padding ('xx') to create a 4-byte (32-bit) word.
            # '<' means little-endian, to match the RISC-V core.

            f.write(struct.pack('<hxx', pixel))

    print(f"Successfully created '{output_filename}'")
    print(f"Total size: {len(flat_data) * 4} bytes (784 32-bit words)")

    # ---------------------------------------------------------------
    # 6. Download the file
    # ---------------------------------------------------------------
    print("Downloading 'image.bin' to your computer...")
    files.download(output_filename)
