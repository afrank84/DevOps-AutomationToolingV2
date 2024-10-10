import json
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
    if len(sys.argv) != 2:
        print("Usage: python script.py <path_to_json_file>")
        sys.exit(1)
    
    json_file_path = sys.argv[1]
    
    try:
        sql_statements = json_to_sql(json_file_path)
        
        # Print SQL statements
        for statement in sql_statements:
            print(statement)
        
        # Optionally, write to a file
        with open('output.sql', 'w') as file:
            for statement in sql_statements:
                file.write(statement + '\n')
        
        print(f"\nGenerated {len(sql_statements)} SQL statements. Also saved to 'output.sql'.")
    
    except FileNotFoundError:
        print(f"Error: File '{json_file_path}' not found.")
    except json.JSONDecodeError:
        print(f"Error: '{json_file_path}' is not a valid JSON file.")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    main()
