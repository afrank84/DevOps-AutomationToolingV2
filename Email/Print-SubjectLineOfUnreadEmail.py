import imaplib
import email
from email.header import decode_header

# Connect to Yahoo Mail IMAP server
username = "your-email@yahoo.com"
password = "your-password"
imap_server = imaplib.IMAP4_SSL("imap.mail.yahoo.com")

# Log in to the server
imap_server.login(username, password)

# Select the mailbox (e.g., inbox)
imap_server.select("inbox")

# Search for unread emails
status, messages = imap_server.search(None, 'UNSEEN')

# Process the emails
for msg_num in messages[0].split():
    res, msg_data = imap_server.fetch(msg_num, "(RFC822)")
    msg = email.message_from_bytes(msg_data[0][1])
    subject, encoding = decode_header(msg["Subject"])[0]
    if isinstance(subject, bytes):
        subject = subject.decode(encoding if encoding else "utf-8")
    print(f"New email with subject: {subject}")

# Close connection
imap_server.close()
imap_server.logout()
