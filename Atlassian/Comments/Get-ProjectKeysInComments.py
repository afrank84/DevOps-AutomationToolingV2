import requests
import re

# Jira credentials and endpoint
JIRA_EMAIL = 'your-email@example.com'
JIRA_API_TOKEN = 'your-api-token'
JIRA_INSTANCE_URL = 'https://your-instance.atlassian.net'

# Regular expression to match Jira issue keys (e.g., ABC-123) that are not part of URLs
ISSUE_KEY_REGEX = r'\b([A-Z]+-\d+)\b(?!\/)'

def get_all_projects():
    """Fetch all Jira projects and return their project keys."""
    url = f'{JIRA_INSTANCE_URL}/rest/api/3/project'
    headers = {
        'Authorization': f'Basic {JIRA_EMAIL}:{JIRA_API_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        projects = response.json()
        # Extract project keys
        project_keys = [project['key'] for project in projects]
        return project_keys
    else:
        print("Failed to fetch projects.")
        return []

def get_issues_from_project(project_key):
    """Fetch all issues for a specific project."""
    url = f'{JIRA_INSTANCE_URL}/rest/api/3/search'
    headers = {
        'Authorization': f'Basic {JIRA_EMAIL}:{JIRA_API_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    query = {
        "jql": f"project = {project_key}",
        "fields": ["key"]
    }
    
    response = requests.post(url, json=query, headers=headers)
    
    if response.status_code == 200:
        issues = response.json().get('issues', [])
        # Return only the issue keys
        return [issue['key'] for issue in issues]
    else:
        print(f"Failed to fetch issues for project {project_key}.")
        return []

def get_issue_comments(issue_key):
    """Fetch comments from a specific issue."""
    url = f'{JIRA_INSTANCE_URL}/rest/api/3/issue/{issue_key}/comment'
    headers = {
        'Authorization': f'Basic {JIRA_EMAIL}:{JIRA_API_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response.json().get('comments', [])
    else:
        print(f"Failed to fetch comments for {issue_key}")
        return []

def search_issue_keys_in_comments(comments, valid_project_keys):
    """Search for issue keys in comments that are not part of a URL and belong to valid projects."""
    found_issue_keys = []
    
    # Iterate through each comment and search for issue keys
    for comment in comments:
        comment_body = comment['body']
        # Find all potential issue keys
        matches = re.findall(ISSUE_KEY_REGEX, comment_body)
        
        # Filter out invalid matches (only keep those that belong to valid projects)
        valid_matches = [match for match in matches if match.split('-')[0] in valid_project_keys]
        found_issue_keys.extend(valid_matches)
    
    return found_issue_keys

def main():
    # Step 1: Fetch all project keys
    project_keys = get_all_projects()
    if not project_keys:
        print("No project keys found. Exiting.")
        return
    
    # Step 2: Iterate over each project to get issues
    for project_key in project_keys:
        print(f"Processing project: {project_key}")
        
        # Get all issues in this project
        issues = get_issues_from_project(project_key)
        
        # Step 3: Iterate over each issue to fetch comments
        for issue_key in issues:
            print(f"Fetching comments for issue: {issue_key}")
            comments = get_issue_comments(issue_key)
            
            if comments:
                # Step 4: Search for issue keys in the comments
                found_issue_keys = search_issue_keys_in_comments(comments, project_keys)
                if found_issue_keys:
                    print(f"Found issue keys in comments for {issue_key}: {found_issue_keys}")
                else:
                    print(f"No valid issue keys found in comments for {issue_key}.")
            else:
                print(f"No comments available for {issue_key}.")

if __name__ == "__main__":
    main()
