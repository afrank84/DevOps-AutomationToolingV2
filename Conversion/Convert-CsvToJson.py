import pandas as pd
import sys
import os

def convert_csv_to_json(file_path):
    try:
        # Check if the file exists
        if not os.path.isfile(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
        
        # Check if the file is a CSV
        if not file_path.endswith(".csv"):
            raise ValueError(f"Input file is not a CSV: {file_path}")
        
        # Read CSV file
        data = pd.read_csv(file_path)
        
        # Convert to JSON and save
        json_file_path = file_path[:-4] + ".json"
        data.to_json(json_file_path, orient='records')
        
        # Provide feedback to the user
        print(f"Successfully converted {file_path} to {json_file_path}")
    
    except FileNotFoundError as fnf_error:
        print(fnf_error)
    except ValueError as ve_error:
        print(ve_error)
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        # Clean up
        if 'data' in locals():
            del data

if __name__ == "__main__":
    # Get command line arguments
    args = sys.argv[1:]
    
    # Ensure a file was provided
    if not args:
        print("No file was provided; Provide a CSV filename")
        sys.exit(1)
    
    # Determine if input is a directory
    isdir = os.path.isdir(args[-1])
    
    # Process the file if it is not a directory
    if not isdir:
        convert_csv_to_json(args[-1])
    else:
        print("Provided input is a directory, not a file")
