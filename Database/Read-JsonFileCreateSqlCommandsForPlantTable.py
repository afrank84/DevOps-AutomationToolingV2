import json
import os
import sys

def json_to_sql(json_file_path):
    # Read the JSON file
    with open(json_file_path, 'r') as file:
        data = json.load(file)
    
    # Generate SQL statements
    sql_statements = []
    for item in data:
        if 'fields' in item and 'Parent' in item['fields'] and 'Variety' in item['fields']:
            parent = item['fields']['Parent'].replace("'", "''")  # Escape single quotes
            variety = item['fields']['Variety'].replace("'", "''")  # Escape single quotes
            sql = f"INSERT INTO Plants (parent, variety) VALUES ('{parent}', '{variety}');"
            sql_statements.append(sql)
    
    return sql_statements

def main():
    # Get the current script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Construct the path to the JSON file
    json_file_path = os.path.join(script_dir, '..', 'Data', 'Vegetable-and-Fruit_data.json')
    
    try:
        # Check if the file exists
        if not os.path.exists(json_file_path):
            raise FileNotFoundError(f"The file '{json_file_path}' does not exist.")
        
        print(f"Processing file: {json_file_path}")
        sql_statements = json_to_sql(json_file_path)
        
        # Print SQL statements
        for statement in sql_statements:
            print(statement)
        
        # Write to a file
        output_file = os.path.join(script_dir, 'output.sql')
        with open(output_file, 'w') as file:
            for statement in sql_statements:
                file.write(statement + '\n')
        
        print(f"\nGenerated {len(sql_statements)} SQL statements.")
        print(f"SQL statements have been saved to: {output_file}")
    
    except FileNotFoundError as e:
        print(f"Error: {str(e)}")
    except json.JSONDecodeError:
        print(f"Error: '{json_file_path}' is not a valid JSON file.")
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")

if __name__ == "__main__":
    main()
