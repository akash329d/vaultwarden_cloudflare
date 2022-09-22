#!/bin/sh

# This is a script designed to backup Vaultwarden data using RSync
# Backs up files defined in https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault
# Backs up every hour (set in crond for rclone alpine docker)

# Check if backup directory and vaultwarden data directory are defined

if [ "$BACKUP_ENABLED" = false ]; then
    echo "Backup disabled; exiting script"
    exit 1
fi

if [ -z "$BACKUP_DIR" ]; then
    echo "Backup dir not defined; exiting script"
    exit 1
fi

if [ -z "$BACKUP_DATA_DIR" ]; then
    echo "Vaultwarden data dir not defined; exiting script"
    exit 1
fi

BACKUP_TMP="${BACKUP_DIR}/tmp"

mkdir -p "${BACKUP_TMP}"

# Generate filenames
DATE_SUFFIX="$(date '+%m_%d_%Y_%H%M')"

DB_BACKUP_DIR="${BACKUP_TMP}/db.${DATE_SUFFIX}.sqlite3"
ATTACHMENTS_BACKUP_DIR="${BACKUP_TMP}/attachments.${DATE_SUFFIX}.zip"
SENDS_BACKUP_DIR="${BACKUP_TMP}/sends.${DATE_SUFFIX}.zip"
CONFIG_JSON_BACKUP_DIR="${BACKUP_TMP}/config.${DATE_SUFFIX}.json"
RSA_KEY_BACKUP_DIR="${BACKUP_TMP}/rsa_key.${DATE_SUFFIX}.zip"

BACKUP_ZIP_DIR="${BACKUP_DIR}/vaultwarden_backup.${DATE_SUFFIX}.zip"


# Backup Database
DB="${BACKUP_DATA_DIR}/db.sqlite3"
if [ -f "$DB" ]; then
    sqlite3 "${DB}" "VACUUM INTO '${DB_BACKUP_DIR}'"
else
    echo "Could not find Vaultwarden DB!"
fi

# Backup Config
CONFIG="${BACKUP_DATA_DIR}/config.json"
if [ -f "$CONFIG" ]; then
    cp -f "${CONFIG}" "${CONFIG_JSON_BACKUP_DIR}"
else
    echo "Could not find Vaultwarden config.json!"
fi

# Backup Attachments
ATTACHMENTS="${BACKUP_DATA_DIR}/attachments"
if [ -d "${ATTACHMENTS}" ]; then
  zip -r "${ATTACHMENTS_BACKUP_DIR}" ${ATTACHMENTS}
else
    echo "Could not find Vaultwarden attachments dir!"
fi

# Backup Sends
SENDS="${BACKUP_DATA_DIR}/sends"
if [ -d "${SENDS}" ]; then
  zip -r "${SENDS_BACKUP_DIR}" ${SENDS}
else
    echo "Could not find Vaultwarden sends dir!"
fi

# Backup RSA (represents current logins, doesn't need to exist)
zip "${RSA_KEY_BACKUP_DIR}" "${BACKUP_DATA_DIR}"/rsa_key*

# Do overall backup
cd "${BACKUP_TMP}"
ls -lah
zip -r "${BACKUP_ZIP_DIR}" ./*
cd -

# Delete temporary backup folder
rm -rf "${BACKUP_TMP}"

# Delete backups older than 15 days
find $BACKUP_DIR/* -mtime +15 -exec rm {} \;

# Do RClone Sync
rclone --config ${BACKUP_RCLONE_CONFIG} sync ${BACKUP_DIR} ${BACKUP_RCLONE_REMOTE_NAME}:${BACKUP_RCLONE_REMOTE_PATH}