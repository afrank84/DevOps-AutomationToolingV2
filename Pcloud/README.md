# pCloud upload

## [Upload-SingleFile.py](Upload-SingleFile.py)

Opens one local file and sends a multipart POST to
`https://api.pcloud.com/uploadfile`. The request includes the configured access
token, basename, `folderid=0` (account root), and `nopartial=1`.

**Requirements:** Python, `requests`, and a pCloud token with upload permission.
In a local copy set `file_path` and `access_token` at the bottom; change
`folderid` inside the function if the root is not the desired destination.
These are code assignments, not CLI options or environment lookups.

```bash
python Pcloud/Upload-SingleFile.py
```

It prints success for HTTP 200 and returns the JSON response to `result`. A 200
response can still contain a pCloud API error, so inspect its `result` field
before relying on the success message. Existing-file behavior follows the API;
there is no local confirmation, retry, timeout, or context manager for the opened
file. The token is placed in request parameters; avoid recording request URLs.
The shipped endpoint is for the configured pCloud region and may need adjustment
for another region. This guide was source-reviewed without performing an upload.
