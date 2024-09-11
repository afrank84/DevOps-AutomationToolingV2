import requests
from requests.auth import HTTPBasicAuth
import json
import os
import urllib3

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Function to load Jira settings from JSON
def load_jira_settings(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Function to search Jira issues
def search_jira_issues(jira_url, jira_email, jira_api_token, project_key, start_at=0, max_results=50):
    url = f"{jira_url}/rest/api/3/search"
    query = {
        "jql": f"project = {project_key}",
        "fields": ["key", "attachment"],
        "startAt": start_at,
        "maxResults": max_results
    }

    # Perform the API request with basic auth
    response = requests.post(
        url,
        json=query,
        auth=HTTPBasicAuth(jira_email, jira_api_token),
        headers={"Content-Type": "application/json"},
        verify=False  # Disable SSL verification
    )

    # Check for a valid response
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Failed to fetch Jira issues: {response.status_code}")
        print(response.text)  # Print error details
        return None

# Function to download attachment
def download_attachment(attachment_url, filename, auth):
    response = requests.get(attachment_url, auth=auth, verify=False)
    
    if response.status_code == 200:
        # Save the file locally
        with open(filename, 'wb') as file:
            file.write(response.content)
        print(f"Downloaded: {filename}")
    else:
        print(f"Failed to download {filename}: {response.status_code}")


# Function to process Jira attachments and maintain the folder structure
def process_attachments(jira_url, jira_email, jira_api_token, project_key, max_attachments):
    start_at = 0
    total_attachments = 0
    auth = HTTPBasicAuth(jira_email, jira_api_token)

    # Base directory for storing attachments
    base_dir = 'attachments'

    while True:
        results = search_jira_issues(jira_url, jira_email, jira_api_token, project_key, start_at)
        if not results or 'issues' not in results:
            break

        issues = results['issues']
        for issue in issues:
            issue_key = issue['key']
            
            if 'attachment' in issue['fields'] and issue['fields']['attachment']:
                # Create directories for each issue only if there are attachments
                project_dir = os.path.join(base_dir, project_key, issue_key)
                if not os.path.exists(project_dir):
                    os.makedirs(project_dir)

                for attachment in issue['fields']['attachment']:
                    filename = os.path.join(project_dir, attachment['filename'])
                    attachment_url = attachment['content']  # This is the download URL
                    attachment_size = attachment['size']  # Get the file size (in bytes)

                    # Print attachment details including size
                    print(f"Processing attachment: {attachment['filename']} from {issue_key}")
                    print(f"Size: {attachment_size / (1024 * 1024):.2f} MB")

                    # Download the attachment
                    download_attachment(attachment_url, filename, auth)

                    total_attachments += 1
                    if total_attachments >= max_attachments:
                        return

        start_at += len(issues)


# Main function to run the script
def main():
    # Load Jira settings from file
    jira_settings = load_jira_settings('jira_settings.json')

    jira_url = jira_settings['jira_url']
    jira_email = jira_settings['jira_email']
    jira_api_token = jira_settings['jira_api_token']
    project_key = jira_settings['project_key']
    max_attachments = jira_settings['max_attachments']

    # Start processing attachments
    process_attachments(jira_url, jira_email, jira_api_token, project_key, max_attachments)

if __name__ == '__main__':
    main()
