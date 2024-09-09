import requests
from requests.auth import HTTPBasicAuth
import json
from pathlib import Path

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

# Jira instance details
config = load_config()
JIRA_URL = config["jira_url"]
USERNAME = config["username"]
API_TOKEN = config["api_token"]

# JQL query to find issues with attachments
JQL_QUERY = "attachments IS NOT EMPTY"

def get_issues_with_attachments():
    url = f"{JIRA_URL}/rest/api/3/search"
    
    auth = HTTPBasicAuth(USERNAME, API_TOKEN)
    
    headers = {
        "Accept": "application/json"
    }
    
    start_at = 0
    max_results = 50
    total = None
    
    issues_with_attachments = []
    total_attachments = 0
    total_size = 0
    
    while total is None or start_at < total:
        params = {
            "jql": JQL_QUERY,
            "startAt": start_at,
            "maxResults": max_results,
            "fields": ["key", "summary", "attachment"]
        }
        
        response = requests.get(url, headers=headers, params=params, auth=auth)
        
        if response.status_code != 200:
            print(f"Error: {response.status_code}")
            print(response.text)
            return None
        
        data = json.loads(response.text)
        
        if total is None:
            total = data["total"]
        
        for issue in data["issues"]:
            issue_key = issue["key"]
            summary = issue["fields"]["summary"]
            attachments = issue["fields"]["attachment"]
            
            issue_attachments = []
            issue_total_size = 0
            for attachment in attachments:
                size = attachment.get("size", 0)
                issue_attachments.append({
                    "filename": attachment["filename"],
                    "size": size
                })
                issue_total_size += size
                total_size += size
            
            issues_with_attachments.append({
                "key": issue_key,
                "summary": summary,
                "attachments": issue_attachments,
                "attachment_count": len(attachments),
                "total_size": issue_total_size
            })
            
            total_attachments += len(attachments)
        
        start_at += max_results
    
    return issues_with_attachments, total_attachments, total_size

def format_size(size_in_bytes):
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_in_bytes < 1024.0:
            return f"{size_in_bytes:.2f} {unit}"
        size_in_bytes /= 1024.0

def main():
    issues, total_attachments, total_size = get_issues_with_attachments()
    
    if issues:
        print(f"Found {len(issues)} issues with attachments:")
        for issue in issues:
            print(f"- {issue['key']}: {issue['summary']}")
            print(f"  Attachments: {issue['attachment_count']}")
            print(f"  Total size: {format_size(issue['total_size'])}")
            for attachment in issue['attachments']:
                print(f"    - {attachment['filename']} ({format_size(attachment['size'])})")
            print()
        
        print(f"Total issues with attachments: {len(issues)}")
        print(f"Total attachments: {total_attachments}")
        print(f"Total size of all attachments: {format_size(total_size)}")
    else:
        print("No issues with attachments found or an error occurred.")

if __name__ == "__main__":
    main()