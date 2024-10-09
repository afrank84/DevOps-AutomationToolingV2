import requests
import json
import os

def load_config():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, '..', 'Data', 'airtable_config.json')
    
    try:
        with open(config_path, 'r') as config_file:
            return json.load(config_file)
    except FileNotFoundError:
        print(f"Config file not found at {config_path}")
        return None
    except json.JSONDecodeError:
        print(f"Error decoding JSON from {config_path}")
        return None

def download_table(base_id, table_name, pat):
    base_url = "https://api.airtable.com/v0"
    headers = {
        "Authorization": f"Bearer {pat}",
        "Content-Type": "application/json"
    }
    
    url = f"{base_url}/{base_id}/{table_name}"
    all_records = []
    
    while True:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            print(f"Error: {response.status_code}")
            print(response.text)
            return None
        
        data = response.json()
        all_records.extend(data['records'])
        
        if 'offset' in data:
            url = f"{base_url}/{base_id}/{table_name}?offset={data['offset']}"
        else:
            break
    
    return all_records

def save_to_json(data, filename):
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)

if __name__ == "__main__":
    config = load_config()
    if not config:
        print("Failed to load configuration. Exiting.")
        exit(1)

    base_id = config.get('BASE_ID')
    table_name = config.get('TABLE_NAME')
    pat = config.get('PAT')

    if not all([base_id, table_name, pat]):
        print("Missing required configuration. Please check your config file.")
        exit(1)

    records = download_table(base_id, table_name, pat)
    if records:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        filename = os.path.join(script_dir, f"{table_name}_data.json")
        save_to_json(records, filename)
        print(f"Data saved to {filename}")
    else:
        print("Failed to download data")