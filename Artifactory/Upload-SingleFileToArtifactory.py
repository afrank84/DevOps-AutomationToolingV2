import requests
from requests.auth import HTTPBasicAuth

# Replace these variables with your details
artifactory_url = "https://your-artifactory-instance/artifactory"
repo_path = "/path/to/repository/folder/file.zip"  # Adjust to your desired repo path
file_path = "/path/to/local/file.zip"  # Adjust to your local file path
username = "your-username"
password = "your-password-or-api-token"

# Full URL to the file in Artifactory
upload_url = f"{artifactory_url}{repo_path}"

# Open the file in binary mode and upload it
with open(file_path, 'rb') as file_to_upload:
    response = requests.put(upload_url, data=file_to_upload, auth=HTTPBasicAuth(username, password))

# Check if the upload was successful
if response.status_code == 201:
    print("File uploaded successfully.")
else:
    print(f"Failed to upload file. Status code: {response.status_code}")
    print(f"Response: {response.text}")
