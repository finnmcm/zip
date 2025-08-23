import csv
import sys
from datetime import datetime

def fix_timestamps(input_file, output_file):
    """Add createdAt and updatedAt timestamp values to each data row"""
    
    # Get current timestamp in YYYY-MM-DD HH:mm:ss format
    current_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.reader(infile)
        writer = csv.writer(outfile)
        
        for row_num, row in enumerate(reader):
            if row_num == 0:  # Header row - keep as is
                writer.writerow(row)
            elif len(row) >= 6:  # Data row with enough fields
                # Add timestamp values to the end
                new_row = row + [current_timestamp, current_timestamp]
                writer.writerow(new_row)
            else:
                # Skip rows that don't have enough fields
                continue

if __name__ == "__main__":
    input_file = "Products_clean.csv"
    output_file = "Products_fixed_timestamps.csv"
    
    try:
        fix_timestamps(input_file, output_file)
        print(f"Successfully added timestamp values to CSV from {input_file} to {output_file}")
        print(f"Timestamp format: YYYY-MM-DD HH:mm:ss")
        print(f"Current timestamp used: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
