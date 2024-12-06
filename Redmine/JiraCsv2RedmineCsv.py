import pandas as pd
from datetime import datetime

def transform_jira_to_redmine(input_file, output_file):
    """
    Transform Jira CSV export format to RedMine CSV import format for The Frank Empire project.
    
    Parameters:
    input_file (str): Path to input Jira CSV file
    output_file (str): Path to output RedMine CSV file
    """
    # Read the Jira CSV file
    df = pd.read_csv(input_file)
    
    # Create a new DataFrame with all RedMine columns
    redmine_columns = [
        '#', 'Project', 'Tracker', 'Parent task', 'Parent task subject',
        'Status', 'Priority', 'Subject', 'Author', 'Assignee', 'Watchers',
        'Updated', 'Category', 'Target version', 'Start date', 'Due date',
        'Estimated time', 'Estimated remaining time', 'Total estimated time',
        'Spent time', 'Total spent time', '% Done', 'Created', 'Closed',
        'Last updated by', 'Related issues', 'Files', 'Label', 'Sprint',
        'Private', 'Description', 'Last notes'
    ]
    
    redmine_df = pd.DataFrame(columns=redmine_columns)
    
    # Fill in the mapped fields
    redmine_df['#'] = range(1, len(df) + 1)
    redmine_df['Project'] = 'The Frank Empire'  # Set project name
    redmine_df['Tracker'] = df['Issue Type'].map({'Task': 'Task', 'Subtask': 'Support'})
    redmine_df['Status'] = df['Status']
    redmine_df['Priority'] = 'Normal'  # Default value
    redmine_df['Subject'] = df['Summary']
    redmine_df['Assignee'] = df['Assignee']
    
    # Handle due date conversion
    def convert_date(date_str):
        if pd.isna(date_str):
            return ''
        try:
            return datetime.strptime(date_str, '%d/%b/%y %I:%M %p').strftime('%Y-%m-%d')
        except:
            return ''
    
    redmine_df['Due date'] = df['Due date'].apply(convert_date)
    
    # Map Labels to Label field
    redmine_df['Label'] = df['Labels']
    
    # Set default values for required fields
    redmine_df['Author'] = ''  # Set to default author if available
    redmine_df['Private'] = 'No'
    redmine_df['% Done'] = '100' if df['Status'] == 'Done' else '0'  # Set 100% if status is Done
    
    # Initialize empty values for other fields
    empty_fields = [
        'Parent task', 'Parent task subject', 'Watchers', 'Updated', 'Category',
        'Target version', 'Start date', 'Estimated time', 'Estimated remaining time',
        'Total estimated time', 'Spent time', 'Total spent time', 'Created',
        'Closed', 'Last updated by', 'Related issues', 'Files', 'Sprint',
        'Description', 'Last notes'
    ]
    
    for field in empty_fields:
        redmine_df[field] = ''
    
    # Optional: Handle parent-child relationships for subtasks
    subtask_mask = df['Issue Type'] == 'Subtask'
    if subtask_mask.any():
        # Set parent task relationships for subtasks
        parent_tasks = df[~subtask_mask]
        for idx, row in df[subtask_mask].iterrows():
            # You might need to adjust this logic based on how parent-child relationships
            # are represented in your Jira export
            pass
    
    # Save to new CSV file
    redmine_df.to_csv(output_file, index=False)
    
    return redmine_df

# Example usage
if __name__ == '__main__':
    input_file = 'jira_export.csv'
    output_file = 'redmine_import.csv'
    
    transformed_data = transform_jira_to_redmine(input_file, output_file)
    print(f"Transformed {len(transformed_data)} issues to RedMine format")
