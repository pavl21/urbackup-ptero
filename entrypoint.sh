#!/bin/bash
set -e

HTTP_PORT="${HTTP_PORT:-55414}"
INTERNET_PORT="${INTERNET_PORT:-55415}"
FASTCGI_PORT="${FASTCGI_PORT:-55413}"
BACKUP_PATH="${BACKUP_PATH:-/home/container/backups}"
LOGLEVEL="${LOGLEVEL:-info}"

# Backup-Verzeichnis anlegen
mkdir -p "$BACKUP_PATH" 2>/dev/null || true
echo -n "$BACKUP_PATH" > /var/urbackup/backupfolder

# Port-Konfiguration ins schreibbare Volume schreiben
CONFIG_FILE="/var/urbackup/urbackupsrv.conf"
cat > "${CONFIG_FILE}" << CONF
FASTCGI_PORT=${FASTCGI_PORT}
HTTP_SERVER=true
HTTP_PORT=${HTTP_PORT}
HTTP_LOCALHOST_ONLY=false
INTERNET_LOCALHOST_ONLY=false
LOGFILE=/var/log/urbackup.log
LOGLEVEL=${LOGLEVEL}
DAEMON_TMPDIR=/tmp
BROADCAST_INTERFACES=
ALLOW_USER_ENUMERATION=true
USER=urbackup
CONF

echo "[UrBackup] Web: Port ${HTTP_PORT} | Clients: Port ${INTERNET_PORT} | Log: ${LOGLEVEL}"

# urbackupsrv mit Filter starten — PID merken für Signal-Weiterleitung
urbackupsrv "$@" --config "${CONFIG_FILE}" 2>&1 | \
  grep --line-buffered -Ev \
    "^Raising nice-ceiling|^Cannot become root user|WARNING: Upgrading database to version [0-9]+" | \
  sed --unbuffered \
    -e 's/WARNING: Upgrading\.\.\./[INFO] Datenbank-Migration läuft.../' \
    -e 's/WARNING: Done\./[INFO] Datenbank-Migration abgeschlossen./' \
    -e 's/WARNING: Creating file entry index.*/[INFO] Datei-Index wird erstellt.../' &

FILTER_PID=$!

# SIGINT/SIGTERM → urbackupsrv beenden (graceful)
_shutdown() {
    URBACKUP_PID=$(pgrep -x urbackupsrv 2>/dev/null | head -1)
    if [ -n "$URBACKUP_PID" ]; then
        echo "[UrBackup] Wird beendet..."
        kill -SIGTERM "$URBACKUP_PID"
        wait "$URBACKUP_PID" 2>/dev/null || true
    fi
    wait "$FILTER_PID" 2>/dev/null || true
    echo "[UrBackup] Beendet."
}

trap _shutdown SIGINT SIGTERM

wait "$FILTER_PID"
