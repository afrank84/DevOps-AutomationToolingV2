# Yahoo IMAP examples

Both Python scripts use standard-library `imaplib` and `email`, connect to Yahoo
IMAP over TLS, and contain local username/password assignments. Configure a local
copy with an account permitted to use IMAP and an appropriate app password. Do
not commit credentials. No live mailbox was used to verify these examples.

## [Print-SubjectLineOfUnreadEmail.py](Print-SubjectLineOfUnreadEmail.py)

Logs in, selects `inbox`, searches for `UNSEEN`, fetches each matching message,
decodes the first subject header fragment, and prints `New email with subject:`.

```bash
python Email/Print-SubjectLineOfUnreadEmail.py
```

Set `username` and `password` in a local copy. Output is terminal-only. Its
`RFC822` fetch can mark messages as read, so this is not a side-effect-free
notification query. Missing subjects, multi-part encodings, login failures, and
unexpected IMAP responses are not robustly handled.

## [Delete-EmailGt7DaysFromSender.py](Delete-EmailGt7DaysFromSender.py)

Selects inbox messages matching a configured sender and an IMAP `BEFORE` date
computed from `days_to_keep` (default 7). It fetches messages to display their
subjects/dates, marks them `\\Deleted`, and calls `expunge()`.

```bash
python Email/Delete-EmailGt7DaysFromSender.py
```

Configure `IMAP_SERVER`, `USERNAME`, `PASSWORD`, `sender_email`, and
`days_to_keep` inside a local copy. The date comparison is IMAP's date-granularity
search, not an exact elapsed-hours check. There is no dry run or confirmation.
**Expunge permanently removes all messages already marked deleted in the selected
mailbox, including ones marked by another client.** Back up and inspect the
mailbox first; the script offers no recovery or per-message retry.
