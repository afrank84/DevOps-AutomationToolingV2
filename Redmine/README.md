# Jira CSV to Redmine CSV

## [JiraCsv2RedmineCsv.py](JiraCsv2RedmineCsv.py)

Draft Python/pandas transformer that reads a Jira CSV and constructs a Redmine
import-shaped table. It copies summaries, status, assignees, and labels; maps
Task to Task and Subtask to Support; sets project/priority defaults; and parses
due dates using `%d/%b/%y %I:%M %p` into ISO dates. Invalid dates become empty.

**Requirements:** Python and pandas. The input must include `Issue Type`,
`Status`, `Summary`, `Assignee`, `Due date`, and `Labels`. Configure the hardcoded
project name and the `input_file`/`output_file` assignments in a local copy.

```bash
python Redmine/JiraCsv2RedmineCsv.py
```

By default it reads `jira_export.csv` and intends to write `redmine_import.csv`
in the current working directory. Output would overwrite an existing file.
It makes no Jira/Redmine API requests and does not import issues itself.

**Known source defect:** `% Done` uses a Python conditional on the pandas Series
`df['Status'] == 'Done'`, which raises an ambiguous-truth-value error for a normal
DataFrame. As written, that prevents the later CSV write. Parent/subtask mapping
is also only a `pass` placeholder, and generated `#` values are row numbers,
not preserved Jira IDs. Treat this as an unfinished transformer requiring a code
fix and import review, not a verified migration tool. No script execution was
used to write this guide.
