### Purpose of print_table.py

The print_table.py script is designed to read a CSV file and display its contents in a formatted table. It provides a user-friendly way to visualize CSV data directly in the terminal using the `tabulate` library. This script is particularly useful for quickly summarizing and inspecting CSV files without needing to open them in a spreadsheet application.

---

### Key Features:
1. **CSV File Validation**:
   - Checks if the specified file exists.
   - Handles errors like missing files or encoding issues gracefully.

2. **Delimiter Detection**:
   - Automatically detects the delimiter used in the CSV file (e.g., `,`, `;`, `|`, or `\t`).
   - Falls back to a default comma delimiter if detection fails.

3. **Empty Row Filtering**:
   - Filters out empty rows to ensure clean and meaningful output.

4. **Formatted Table Output**:
   - Uses the `tabulate` library to display the CSV data in a visually appealing table format.
   - Supports multiple table formats (e.g., `plain`, `grid`, `pipe`, `html`, `latex`, etc.).

5. **Command-Line Usability**:
   - Can be executed from the command line with the following syntax:
     
     ```bash
     python3 print_table.py <csv_file> [table_format]
     ```

   - The `table_format` argument is optional and defaults to `"simple_grid"`.

---

### How to Use:
1. **Basic Usage**:
   Run the script with the path to a CSV file:
   
   ```bash
   python3 print_table.py data.csv
   ```
   
   This will display the contents of `data.csv` in a table with the default format.

2. **Custom Table Format**:
   Specify a custom table format as the second argument:
   
   ```bash
   python3 print_table.py data.csv grid
   ```

   This will display the table using the `grid` format.

3. **Error Handling**:
   - If the file does not exist, the script will print an error message.
   - If the file has encoding issues, it will suggest using UTF-8 encoding.
   - If the CSV is empty, it will warn the user.

---

### Example Output:
For a CSV file `data.csv` with the following content:
```csv
Name,Age,Department
Alice,30,Engineering
Bob,25,Marketing
Charlie,35,HR
```

Running the script:
```bash
python3 print_table.py data.csv grid
```

Output:
```
+---------+-----+-------------+
| Name    | Age | Department  |
+---------+-----+-------------+
| Alice   |  30 | Engineering |
| Bob     |  25 | Marketing   |
| Charlie |  35 | HR          |
+---------+-----+-------------+
```

---

### Use Cases:
- **Data Inspection**: Quickly inspect the contents of a CSV file in a readable format.
- **Debugging**: Verify the structure and data of CSV files during development.
- **Automation**: Integrate into scripts or workflows for automated data visualization.