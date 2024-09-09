import requests
from requests.auth import HTTPBasicAuth
import json

# Jira instance details
JIRA_URL = "https://your-domain.atlassian.net"
JIRA_EMAIL = "your-email@example.com"
JIRA_API_TOKEN = "your-api-token"

# The URL you want to find and replace
OLD_URL = "http://old-url.com"
NEW_URL = "http://new-url.com"

def search_comments_with_url(jql):
    url = f"{JIRA_URL}/rest/api/3/search"
    
    headers = {
        "Accept": "application/json"
    }
    
    query = {
        'jql': jql,
        'fields': ['comment']
    }
    
    response = requests.get(
        url,
        headers=headers,
        params=query,
        auth=HTTPBasicAuth(JIRA_EMAIL, JIRA_API_TOKEN)
    )
    
    return response.json()

def update_comment(issue_id, comment_id, body):
    url = f"{JIRA_URL}/rest/api/3/issue/{issue_id}/comment/{comment_id}"
    
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    
    payload = json.dumps({
        "body": {
            "type": "doc",
            "version": 1,
            "content": [
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "text": body,
                            "type": "text"
                        }
                    ]
                }
            ]
        }
    })
    
    response = requests.put(
        url,
        data=payload,
        headers=headers,
        auth=HTTPBasicAuth(JIRA_EMAIL, JIRA_API_TOKEN)
    )
    
    return response.status_code

# Search for issues with comments containing the old URL
jql = f'comment ~ "{OLD_URL}"'
search_results = search_comments_with_url(jql)

for issue in search_results['issues']:
    for comment in issue['fields']['comment']['comments']:
        if OLD_URL in comment['body']:
            new_body = comment['body'].replace(OLD_URL, NEW_URL)
            status = update_comment(issue['key'], comment['id'], new_body)
            print(f"Updated comment {comment['id']} in issue {issue['key']}: status {status}")

print("Finished updating comments.")
