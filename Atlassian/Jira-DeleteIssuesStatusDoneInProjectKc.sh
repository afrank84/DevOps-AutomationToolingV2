#!/bin/bash

# Variables
JiraUrl=$JIRA_URL       # Replace with your Jira URL
Username=$JIRA_USERNAME # Replace with your Jira username
Password=$JIRA_API      # Replace with your Jira API token or password

# Base64 encode your credentials
base64AuthInfo=$(echo -n "${Username}:${Password}" | base64)

# Set up the REST API URL for searching issues in Project KC with a status of "Done"
SearchIssuesUrl="${JiraUrl}/rest/api/2/search"

# Define the JQL query to find issues in Project KC with a status of "Done"
JqlQuery="project = KC AND status = Done"

# Define headers for the API request
headers="Authorization: Basic ${base64AuthInfo}"

# Send the POST request to search for issues
response=$(curl -s -X POST -H "${headers}" -H "Content-Type: application/json" \
    --data "{\"jql\": \"${JqlQuery}\", \"maxResults\": 1000}" "${SearchIssuesUrl}")

# Check if the response is empty or not
if [[ -z "$response" ]]; then
    echo "Error: No response from Jira API"
    exit 1
fi

# Loop through the retrieved issues and delete them
issue_keys=$(echo "$response" | jq -r '.issues[].key')

for IssueKey in $issue_keys; do
    DeleteIssueUrl="${JiraUrl}/rest/api/2/issue/${IssueKey}"
    
    # Send the DELETE request to delete the issue
    delete_response=$(curl -s -X DELETE -H "${headers}" "${DeleteIssueUrl}")
    
    if [[ $? -eq 0 ]]; then
        echo "Issue $IssueKey has been deleted successfully."
    else
        echo "Error deleting issue $IssueKey."
    fi
done

#Commands: Use in Terminal first to get this to run
#chmod +x delete_jira_issues.sh
#./delete_jira_issues.sh


