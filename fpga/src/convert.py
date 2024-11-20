import binascii

def convert_bin_to_hex_per_line(input_bin_file, output_txt_file):
    try:
        with open(input_bin_file, 'rb') as bin_file:
            binary_data = bin_file.read()
        hex_data = binascii.hexlify(binary_data).decode('utf-8')
        byte_list = [hex_data[i:i+2] for i in range(0, len(hex_data), 2)]
        with open(output_txt_file, 'w') as txt_file:
            txt_file.write('\n'.join(byte_list))
        print(f"Conversion complete! Hexadecimal data saved to {output_txt_file}.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='convert binary file to .txt')
    parser.add_argument('--input', metavar='path', required=True, help='input file (.bin or .rom)')
    parser.add_argument('--output', metavar='path', required=True, help='output file (.txt)')
    args = parser.parse_args()
    convert_bin_to_hex_per_line(args.input, args.output)    
