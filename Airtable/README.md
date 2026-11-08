# Airtable table export

## [Download-DatabaseWithPat.py](Download-DatabaseWithPat.py)

Exports the records of **one configured table**, not an entire Airtable database.
The Python script reads configuration, sends authenticated GET requests, follows
each returned `offset`, and accumulates the table's record objects in memory.

**Requirements:** Python, `requests`, network access to `api.airtable.com`, and
an Airtable personal access token with record-read access to the selected base.

Create a local `Data/airtable_config.json`, relative to the repository root:

```json
{"BASE_ID":"app_example","TABLE_NAME":"Example Table","PAT":"YOUR_LOCAL_TOKEN"}
```

Keep the real token out of Git. The script reads that JSON file; it does not read
an environment variable or command-line argument for these settings.

```bash
python Airtable/Download-DatabaseWithPat.py
```

**Output:** `Airtable/<TABLE_NAME>_data.json`, containing the array of API record
objects, including record metadata. It overwrites a same-name local file. An empty
table prints a failure message rather than writing an empty array. Configuration
errors exit early; HTTP errors print the status and response. There is no request
timeout, retry, attachment download, schema export, or memory limit. Table names
are used directly in the request path and output filename, so review unusual
characters. These instructions are source-reviewed, not an executed API test.
