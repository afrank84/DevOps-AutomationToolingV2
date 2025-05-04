#!/bin/bash

# ---- Configurable Variables ----
SSH_USER="currentUserHere"
SSH_HOST="sharedIp"
SSH_PORT=2222
SSH_KEY="$HOME/.ssh/id_rsa_inmotion"

DB_NAME="your_database_name"
DB_USER="your_database_user"
DB_PASS="your_database_password"

# ---- Output Path ----
DATE=$(date +%F)
BACKUP_DIR="$HOME/Downloads"
BACKUP_FILE="$BACKUP_DIR/plantrodeo_backup_${DATE}.sql"

# ---- Run Backup ----
echo "Starting backup of $DB_NAME from $SSH_HOST..."
ssh -p $SSH_PORT -i "$SSH_KEY" "$SSH_USER@$SSH_HOST" \
"mysqldump -u $DB_USER -p'$DB_PASS' $DB_NAME" > "$BACKUP_FILE"

# ---- Confirm Result ----
if [[ $? -eq 0 ]]; then
    echo "✅ Backup successful: $BACKUP_FILE"
else
    echo "❌ Backup failed."
    exit 1
fi
