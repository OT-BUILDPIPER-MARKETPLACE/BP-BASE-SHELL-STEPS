#!/usr/bin/env python3

import csv
import os
import sys
from tabulate import tabulate

def summarize_csv(file_path, table_format="simple_grid"):
    """
    Reads a CSV file and prints its contents in a formatted table.

    Parameters:
    - file_path (str): The path to the CSV file.
    - table_format (str): The format style for the table (default: "simple_grid").
      Available formats: "plain", "grid", "pipe", "html", "latex", etc.

    Returns:
    - None (prints the table to stdout)
    """

    # Check if file exists
    if not os.path.isfile(file_path):
        print(f"\033[91mError: File '{file_path}' not found.\033[0m")
        return
    
    try:
        with open(file_path, newline='', encoding='utf-8') as csvfile:
            # Auto-detect delimiter
            sample = csvfile.read(1024)
            csvfile.seek(0)
            try:
                dialect = csv.Sniffer().sniff(sample, delimiters=",;|\t")
            except csv.Error:
                print("\033[93mWarning: Unable to determine delimiter. Defaulting to comma.\033[0m")
                dialect = csv.get_dialect("excel")  # Defaults to comma

            reader = csv.reader(csvfile, dialect)
            data = [row for row in reader if any(row)]  # Filter out empty rows

        # Check if the CSV is empty
        if not data:
            print("\033[93mWarning: The CSV file is empty or contains only empty rows.\033[0m")
            return

        # Print the formatted table
        print("\n" + tabulate(data, headers="firstrow", tablefmt=table_format) + "\n")

    except UnicodeDecodeError:
        print("\033[91mError: Failed to read CSV due to encoding issues. Try using UTF-8 encoding.\033[0m")
    except Exception as e:
        print(f"\033[91mError: Failed to process CSV - {e}\033[0m")

# Run from command line
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("\033[91mUsage: python3 summarize_csv.py <csv_file> [table_format]\033[0m")
        sys.exit(1)

    csv_file = sys.argv[1]
    table_fmt = sys.argv[2] if len(sys.argv) > 2 else "simple_grid"
    summarize_csv(csv_file, table_fmt)
