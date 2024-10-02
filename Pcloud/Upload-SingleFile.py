import requests
import os

def upload_to_pcloud(file_path, access_token):
    # pCloud API endpoint for file upload
    upload_url = "https://api.pcloud.com/uploadfile"

    # Prepare the file for upload
    files = {
        'file': open(file_path, 'rb')
    }

    # Prepare the parameters
    params = {
        'access_token': access_token,
        'folderid': 0,  # Root folder. Change this if you want to upload to a specific folder
        'filename': os.path.basename(file_path),
        'nopartial': 1
    }

    # Make the API request
    response = requests.post(upload_url, files=files, params=params)

    # Check the response
    if response.status_code == 200:
        print("File uploaded successfully!")
        return response.json()
    else:
        print(f"Error uploading file. Status code: {response.status_code}")
        return None

# Usage example
file_path = "/path/to/your/file.txt"
access_token = "YOUR_ACCESS_TOKEN"
result = upload_to_pcloud(file_path, access_token)
