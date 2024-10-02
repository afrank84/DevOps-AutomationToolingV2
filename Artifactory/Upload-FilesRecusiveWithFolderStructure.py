import os
import requests

def upload_to_artifactory(local_path, artifactory_url, repo_path, api_key):
    headers = {
        'X-JFrog-Art-Api': api_key,
        'Content-Type': 'application/octet-stream'
    }
    
    for root, dirs, files in os.walk(local_path):
        for file in files:
            local_file_path = os.path.join(root, file)
            relative_path = os.path.relpath(local_file_path, local_path)
            artifactory_file_path = f"{artifactory_url}/{repo_path}/{relative_path}"
            
            with open(local_file_path, 'rb') as file_content:
                response = requests.put(artifactory_file_path, headers=headers, data=file_content)
                
                if response.status_code == 201:
                    print(f"Successfully uploaded: {relative_path}")
                else:
                    print(f"Failed to upload: {relative_path}. Status code: {response.status_code}")

# Example usage
local_path = '/path/to/your/local/folders'
artifactory_url = 'https://your-artifactory-instance.com/artifactory'
repo_path = 'your-repository-name'
api_key = 'your-api-key'

upload_to_artifactory(local_path, artifactory_url, repo_path, api_key)
