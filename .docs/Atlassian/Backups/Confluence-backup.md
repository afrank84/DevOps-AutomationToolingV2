This Bash script is designed to perform an automated backup of a Confluence instance using the Atlassian API. Here's what each section and command does:

---

### **Configuration Section**
- **Variables:**
  - `EMAIL`: Email address for authentication.
  - `API_TOKEN`: Atlassian API token for authentication.
  - `INSTANCE`: The base URL of your Confluence instance (e.g., `xxx.atlassian.net`).
  - `DOWNLOAD_FOLDER`: Absolute path where the backup will be saved.
  - `INCLUDE_ATTACHMENTS`: Whether to include attachments in the backup (`true` or `false`).
  - `PROGRESS_CHECKS`: Number of times to check the backup status.
  - `SLEEP_SECONDS`: Delay between each backup status check.
  - `TIMEZONE`: Timezone to format the backup date properly.

---

### **Backup Process**
1. **Initialize the Date**
   - `TODAY=$(TZ=$TIMEZONE date +%d-%m-%Y)`: Sets the current date in `DD-MM-YYYY` format for the specified timezone.

2. **Start Backup Request**
   - Sends a POST request to Confluence's API to initiate the backup:
     ```bash
     curl -s -u ${EMAIL}:${API_TOKEN} -H "X-Atlassian-Token: no-check" -H "X-Requested-With: XMLHttpRequest" -H "Content-Type: application/json" -X POST "https://${INSTANCE}/wiki/rest/obm/1.0/runbackup" -d "{\"cbAttachments\":\"$INCLUDE_ATTACHMENTS\" }"
     ```
   - `-u ${EMAIL}:${API_TOKEN}`: Basic authentication using the email and API token.
   - `-H`: Sets headers for the request.
   - `-d`: Specifies the JSON payload with the backup settings (e.g., whether to include attachments).

3. **Handle Backup Initiation Response**
   - Checks if the response contains "backup" to detect failure:
     ```bash
     if [ "$(echo "$BKPMSG" | grep -ic backup)" -ne 0 ]; then
     ```

---

### **Backup Status Check**
4. **Loop for Progress Monitoring**
   - Loops up to `PROGRESS_CHECKS` times, checking every `SLEEP_SECONDS` seconds.
   - Uses the `getprogress.json` API to check the status of the backup:
     ```bash
     curl -s -u ${EMAIL}:${API_TOKEN} https://${INSTANCE}/wiki/rest/obm/1.0/getprogress.json
     ```
   - Extracts the `fileName` from the JSON response:
     ```bash
     FILE_NAME=$(echo "$PROGRESS_JSON" | sed -n 's/.*"fileName"[ ]*:[ ]*"\([^"]*\).*/\1/p')
     ```
   - Prints the JSON response for monitoring purposes.

5. **Error and Completion Handling**
   - If an `"error"` is detected in the response, the loop exits.
   - If a `fileName` is present, it indicates the backup file is ready.

---

### **Download the Backup**
6. **Final Download**
   - If the backup is ready, it constructs the download URL:
     ```bash
     https://${INSTANCE}/wiki/download/$FILE_NAME
     ```
   - Downloads the file using `curl` and saves it to the specified `DOWNLOAD_FOLDER`:
     ```bash
     curl -s -L -u ${EMAIL}:${API_TOKEN} "https://${INSTANCE}/wiki/download/$FILE_NAME" -o "$DOWNLOAD_FOLDER/CONF-backup-${TODAY}.zip"
     ```

---

### **Error Handling**
- If the backup does not complete after the configured `PROGRESS_CHECKS`, the script exits without downloading a file.

---

### **Key Features**
- **Authentication**: Uses email and API token for secure access.
- **Progress Monitoring**: Repeatedly checks the backup status until completion or timeout.
- **Timezone Handling**: Adjusts the date format based on the specified timezone.
- **Error Logging**: Prints API responses and terminates on errors.
- **Download Automation**: Automatically downloads the backup file when ready.

---

### **Usage Notes**
- Ensure that:
  - All variables (`EMAIL`, `API_TOKEN`, `INSTANCE`, `DOWNLOAD_FOLDER`) are configured before running.
  - The script has execution permissions (`chmod +x script.sh`).
  - The `DOWNLOAD_FOLDER` exists and has write permissions.

This script is robust for automating Confluence backups, with configurable retries and delays to handle large instances.
