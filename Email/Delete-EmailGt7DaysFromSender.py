import imaplib
import email
from email.utils import parsedate_to_datetime
from datetime import datetime, timedelta

# IMAP Server and login details
IMAP_SERVER = 'imap.mail.yahoo.com'
USERNAME = 'your-email@yahoo.com'
PASSWORD = 'your-app-password'  # Use an app password if 2FA is enabled

# Connect to the Yahoo IMAP server
mail = imaplib.IMAP4_SSL(IMAP_SERVER)
mail.login(USERNAME, PASSWORD)

# Select the 'inbox' folder
mail.select("inbox")

# Define the sender's email and the date range
sender_email = "example@domain.com"
days_to_keep = 7
cutoff_date = (datetime.now() - timedelta(days=days_to_keep)).strftime("%d-%b-%Y")

# Search for emails from the sender older than the cutoff date
search_query = f'(FROM "{sender_email}" BEFORE {cutoff_date})'
status, messages = mail.search(None, search_query)

if status == 'OK':
    for num in messages[0].split():
        # Fetch the email to confirm the deletion (optional)
        status, data = mail.fetch(num, '(RFC822)')
        msg = email.message_from_bytes(data[0][1])
        subject = msg["subject"]
        date = parsedate_to_datetime(msg["Date"])

        print(f"Deleting: {subject} from {date}")

        # Mark the email for deletion
        mail.store(num, '+FLAGS', '\\Deleted')

    # Permanently delete all emails marked as \Deleted
    mail.expunge()

# Close the connection and logout
mail.close()
mail.logout()
