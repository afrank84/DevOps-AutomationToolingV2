import requests
import json
from datetime import datetime

def load_jira_settings(file_path='jira_settings.json'):
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
            'fields': 'key'
        }
        response = requests.get(search_url, auth=auth, params=params)
        response.raise_for_status()
        data = response.json()
        
        issues.extend(data['issues'])
        
        if len(issues) >= data['total']:
            break
        
        start_at += max_results

    return [issue['key'] for issue in issues]

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
                closed_timestamp = datetime.fromisoformat(history['created'].replace('Z', '+00:00'))
                break
        if closed_timestamp:
            break

    if not closed_timestamp:
        return False, "Issue has not been closed yet"

    for history in issue_data['changelog']['histories']:
        change_timestamp = datetime.fromisoformat(history['created'].replace('Z', '+00:00'))
        if change_timestamp > closed_timestamp:
            return True, f"Modified after closure. Last change: {change_timestamp}"

    return False, "No changes detected after closure"

def main():
    try:
        settings = load_jira_settings()
        project_key = input("Enter the Jira project key: ")
        
        defect_keys = get_all_defects(project_key, settings)
        print(f"Found {len(defect_keys)} defects in project {project_key}")
        
        modified_after_closure = []
        for issue_key in defect_keys:
            changed, message = check_issue_changes_after_closure(issue_key, settings)
            if changed:
                modified_after_closure.append((issue_key, message))
            print(f"Checked {issue_key}: {message}")
        
        print("\nSummary:")
        print(f"Total defects checked: {len(defect_keys)}")
        print(f"Defects modified after closure: {len(modified_after_closure)}")
        
        if modified_after_closure:
            print("\nDefects modified after closure:")
            for issue_key, message in modified_after_closure:
                print(f"{issue_key}: {message}")

    except FileNotFoundError:
        print("Error: jira_settings.json file not found.")
    except json.JSONDecodeError:
        print("Error: Invalid JSON in jira_settings.json file.")
    except KeyError as e:
        print(f"Error: Missing key in jira_settings.json: {e}")
    except requests.RequestException as e:
        print(f"Error connecting to Jira: {e}")

if __name__ == "__main__":
    main()