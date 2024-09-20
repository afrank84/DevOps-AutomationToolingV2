import requests
import json
from datetime import datetime
import os
from dateutil import parser

SETTINGS_PATH = os.path.join(os.path.dirname(__file__), '..', '..', 'Data', 'jira_settings.json')

def load_jira_settings(file_path=SETTINGS_PATH):
    with open(file_path, 'r') as f:
        return json.load(f)

def get_all_defects(project_key, settings):
    jira_url = settings['jira_url']
    auth = (settings['jira_email'], settings['jira_api_token'])
    
    jql = f"project = {project_key} AND issuetype = Defect"
    search_url = f"{jira_url}/rest/api/3/search"
    
    issues = []
    start_at = 0
    max_results = 100

    while True:
        params = {
            'jql': jql,
            'startAt': start_at,
            'maxResults': max_results,
            'fields': 'key,issuetype'
        }
        response = requests.get(search_url, auth=auth, params=params)
        response.raise_for_status()
        data = response.json()
        
        issues.extend(data['issues'])
        
        if len(issues) >= data['total']:
            break
        
        start_at += max_results

    return [(issue['key'], issue['fields']['issuetype']['name']) for issue in issues]

def check_issue_changes_after_closure(issue_key, settings):
    jira_url = settings['jira_url']
    auth = (settings['jira_email'], settings['jira_api_token'])

    issue_url = f"{jira_url}/rest/api/3/issue/{issue_key}"
    response = requests.get(issue_url, auth=auth, params={'expand': 'changelog'})
    response.raise_for_status()
    issue_data = response.json()

    closed_timestamp = None
    for history in issue_data['changelog']['histories']:
        for item in history['items']:
            if item['field'] == 'status' and item['toString'] == 'Closed':
                closed_timestamp = parser.parse(history['created'])
                break
        if closed_timestamp:
            break

    if not closed_timestamp:
        return False, "Issue has not been closed yet", None

    post_closure_changes = []
    for history in issue_data['changelog']['histories']:
        change_timestamp = parser.parse(history['created'])
        if change_timestamp > closed_timestamp:
            # Use get() method with a default value to avoid KeyError
            author = history.get('author', {}).get('displayName', 'Unknown User')
            changes = []
            for item in history['items']:
                if item['field'] == 'attachment':
                    changes.append(f"Attachment added: {item.get('toString', 'Unknown attachment')}")
                elif item['field'] == 'comment':
                    changes.append("Comment added")
                else:
                    changes.append(f"{item['field']} changed from '{item.get('fromString', 'Unknown')}' to '{item.get('toString', 'Unknown')}'")
            post_closure_changes.append({
                'timestamp': change_timestamp,
                'author': author,
                'changes': changes
            })

    if post_closure_changes:
        last_change = post_closure_changes[-1]
        summary = f"Modified after closure. Last change by {last_change['author']} at {last_change['timestamp']}"
        return True, summary, post_closure_changes
    
    return False, "No changes detected after closure", None

def main():
    try:
        settings = load_jira_settings()
        project_key = input("Enter the Jira project key: ")
        
        defect_keys = get_all_defects(project_key, settings)
        print(f"Found {len(defect_keys)} defects in project {project_key}")
        
        modified_after_closure = []
        for issue_key, issue_type in defect_keys:
            changed, message, details = check_issue_changes_after_closure(issue_key, settings)
            if changed:
                modified_after_closure.append((issue_key, issue_type, message, details))
            print(f"Checked {issue_key} (Type: {issue_type}): {message}")
        
        print("\nSummary:")
        print(f"Total defects checked: {len(defect_keys)}")
        print(f"Defects modified after closure: {len(modified_after_closure)}")
        
        if modified_after_closure:
            print("\nDefects modified after closure:")
            for issue_key, issue_type, message, details in modified_after_closure:
                print(f"\n{issue_key} (Type: {issue_type}): {message}")
                print("Detailed changes:")
                for change in details:
                    print(f"  - At {change['timestamp']} by {change['author']}:")
                    for item in change['changes']:
                        print(f"    * {item}")

    except FileNotFoundError:
        print(f"Error: jira_settings.json file not found at {SETTINGS_PATH}")
    except json.JSONDecodeError:
        print("Error: Invalid JSON in jira_settings.json file.")
    except KeyError as e:
        print(f"Error: Missing key in jira_settings.json: {e}")
    except requests.RequestException as e:
        print(f"Error connecting to Jira: {e}")

if __name__ == "__main__":
    main()