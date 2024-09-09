# Jira Attachment Finder

This Python script helps you find and analyze attachments in your Jira issues. It uses the Jira REST API to search for issues with attachments and provides detailed information about each attachment, including file sizes and total counts.

## Features

- Searches for all Jira issues containing attachments
- Provides detailed information for each issue, including:
  - Issue key and summary
  - Number of attachments
  - Total size of attachments for each issue
  - Individual attachment names and sizes
- Calculates and displays overall statistics:
  - Total number of issues with attachments
  - Total number of attachments across all issues
  - Total size of all attachments

## Prerequisites

- Python 3.6 or higher
- `requests` library

## Setup

1. Clone this repository or download the `jira_attachment_finder.py` script.

2. Install the required `requests` library:
   ```
   pip install requests
   ```

3. Create a `config.json` file in the same directory as the script with the following structure:
   ```json
   {
       "jira_url": "https://your-jira-instance.atlassian.net",
       "username": "your_username",
       "api_token": "your_api_token"
   }
   ```
   Replace the placeholder values with your actual Jira URL, username, and API token.

4. To get an API token:
   - Log in to https://id.atlassian.com/manage/api-tokens
   - Click "Create API token"
   - Give your token a name and click "Create"
   - Copy the token and paste it into your `config.json` file

## Usage

Run the script from the command line:

```
python jira_attachment_finder.py
```

The script will output information about each issue with attachments, including:
- Issue key and summary
- Number of attachments for the issue
- Total size of attachments for the issue
- List of attachments with their individual sizes

At the end, it will display summary statistics for all issues found.

![image](https://github.com/user-attachments/assets/277917e2-3d05-4712-a3f2-a12a4fc40500)


## Customization

You can modify the `JQL_QUERY` variable in the script to change the search criteria for issues. The default query `"attachments IS NOT EMPTY"` finds all issues with attachments, but you can add additional conditions to narrow down the search.

## Troubleshooting

- If you encounter a "File not found" error, make sure the `config.json` file is in the same directory as the script.
- If you get authentication errors, double-check your username and API token in the `config.json` file.
- For other API-related errors, verify that your Jira URL is correct and that your account has the necessary permissions to access issue data.

## Contributing

Feel free to fork this repository and submit pull requests with any enhancements.

## License

This project is open source and available under the [MIT License](https://opensource.org/licenses/MIT).
