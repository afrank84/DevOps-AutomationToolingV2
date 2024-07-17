# CSV to JSON Converter Script

## Description

This script converts a specified CSV file to a JSON file. The JSON file will have the same name as the CSV file but with a `.json` extension. The script performs various checks to ensure that the provided file exists and is in the correct format before attempting the conversion.

## Requirements

- Python 3.x
- pandas library

## Installation

1. **Install Python 3.x** if you haven't already. You can download it from [python.org](https://www.python.org/downloads/).

2. **Install the pandas library**. You can install it using pip:
   ```bash
   pip install pandas
   ```

## Usage

1. **Save the script to a file** named `csv_to_json.py`.

2. **Open a terminal or command prompt**.

3. **Navigate to the directory** where `csv_to_json.py` is saved.

4. **Run the script** with the path to the CSV file as an argument:
   ```bash
   python csv_to_json.py path/to/yourfile.csv
   ```

   Replace `path/to/yourfile.csv` with the actual path to your CSV file.

## Example

```bash
python csv_to_json.py data.csv
```

If `data.csv` is located in the same directory as the script, the above command will convert `data.csv` to `data.json` in the same directory.

## Error Handling

The script performs several checks and will print appropriate error messages if:
- No file is provided.
- The provided input is a directory instead of a file.
- The file does not exist.
- The file is not a CSV file.

## Script Details

### Function: `convert_csv_to_json(file_path)`

This function performs the main task of converting a CSV file to a JSON file. It:
- Checks if the file exists.
- Verifies if the file has a `.csv` extension.
- Reads the CSV file using pandas.
- Converts the CSV data to JSON format.
- Saves the JSON data to a new file with the same name as the CSV file but with a `.json` extension.
- Prints a success message upon completion.

### Main Execution Block

The script:
- Retrieves command line arguments.
- Checks if a file was provided.
- Determines if the input is a directory.
- Calls the `convert_csv_to_json` function if the input is a valid file.

## Notes

- Ensure the CSV file is properly formatted before running the script.
- The script will overwrite any existing JSON file with the same name in the same directory.

## License

This script is provided "as-is" without any warranty. Feel free to modify and use it as needed.

## Contributing

If you find any issues or have suggestions for improvements, please feel free to submit a pull request or open an issue.

---

This README provides a comprehensive guide to using the CSV to JSON converter script, including installation, usage, error handling, and detailed descriptions of the script's functionality.
