import requests
import json
import os

# Airtable API endpoint
BASE_URL = "https://api.airtable.com/v0"

# Your Airtable base ID and table name
BASE_ID = "your_base_id_here"
TABLE_NAME = "your_table_name_here"

# Your personal access token
PAT = "your_personal_access_token_here"

def download_table(base_id, table_name, pat):
    headers = {
        "Authorization": f"Bearer {pat}",
        "Content-Type": "application/json"
    }
    
    url = f"{BASE_URL}/{base_id}/{table_name}"
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
            url = f"{BASE_URL}/{base_id}/{table_name}?offset={data['offset']}"
        else:
            break
    
    return all_records

def save_to_json(data, filename):
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)

if __name__ == "__main__":
    records = download_table(BASE_ID, TABLE_NAME, PAT)
    if records:
        filename = f"{TABLE_NAME}_data.json"
        save_to_json(records, filename)
        print(f"Data saved to {filename}")
    else:
        print("Failed to download data")
