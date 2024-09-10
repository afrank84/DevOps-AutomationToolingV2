import requests
import json
from pathlib import Path
from requests.auth import HTTPBasicAuth

# Load configuration from JSON file
def load_config(file_path="config.json"):
    try:
        with open(file_path, "r") as config_file:
            return json.load(config_file)
    except FileNotFoundError:
        print(f"Error: {file_path} not found. Please create this file with your Jira credentials.")
        exit(1)
    except json.JSONDecodeError:
        print(f"Error: {file_path} is not a valid JSON file.")
        exit(1)

# Load Jira instance details from config.json
config = load_config()
JIRA_URL = config["jira_url"]
USERNAME = config["username"]
API_TOKEN = config["api_token"]

# Function to get issue data from Jira API using HTTPBasicAuth
def get_jira_issue(issue_key):
    url = f"{JIRA_URL}/rest/api/3/issue/{issue_key}"
    auth = HTTPBasicAuth(USERNAME, API_TOKEN)
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    
    # Make the request using HTTPBasicAuth
    response = requests.get(url, headers=headers, auth=auth)
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching issue {issue_key}: {response.status_code}")
        print(response.text)  # Print detailed error message for troubleshooting
        return None

# Function to convert Jira issue data to markdown
def convert_issue_to_markdown(issue_data, output_file):
    summary = issue_data['fields']['summary']
    description = issue_data['fields']['description'] or "No description provided."
    status = issue_data['fields']['status']['name']
    priority = issue_data['fields']['priority']['name'] if issue_data['fields']['priority'] else "No priority"
    assignee = issue_data['fields']['assignee']['displayName'] if issue_data['fields']['assignee'] else "Unassigned"
    created = issue_data['fields']['created']
    comments = issue_data['fields']['comment']['comments']

    # Create markdown content
    md_content = f"""
# Issue: {issue_data['key']} - {summary}

**Status**: {status}  
**Priority**: {priority}  
**Assignee**: {assignee}  
**Created**: {created}

## Description
{description}

## Comments
"""
    for comment in comments:
        author = comment['author']['displayName']
        body = comment['body']['content'][0]['content'][0]['text']
        md_content += f"\n### Comment by {author}\n{body}\n"

    # Save markdown content to a file
    with open(output_file, 'w') as md_file:
        md_file.write(md_content)

    print(f"Markdown file {output_file} created successfully.")

def main():
    issue_key = input("Enter the Jira issue key (e.g., PROJECT-123): ")
    issue_data = get_jira_issue(issue_key)

    if issue_data:
        output_file = f"{issue_key}.md"
        convert_issue_to_markdown(issue_data, output_file)

if __name__ == "__main__":
    main()
