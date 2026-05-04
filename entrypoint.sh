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

# urbackupsrv starten — harmlose Meldungen filtern, PID für Shutdown merken
urbackupsrv "$@" --config "${CONFIG_FILE}" 2>&1 | \
  grep --line-buffered -Ev \
    "^Raising nice-ceiling|^Cannot become root user|WARNING: Upgrading database to version [0-9]+" | \
  sed --unbuffered \
    -e 's/WARNING: Upgrading\.\.\./[INFO] Datenbank-Migration läuft.../' \
    -e 's/WARNING: Done\./[INFO] Datenbank-Migration abgeschlossen./' \
    -e 's/WARNING: Creating file entry index.*/[INFO] Datei-Index wird erstellt.../' &

FILTER_PID=$!

# urbackupsrv PID via /proc ermitteln (kein pgrep nötig)
_get_urbackup_pid() {
    for f in /proc/[0-9]*/cmdline; do
        if grep -q "urbackupsrv" "$f" 2>/dev/null; then
            echo "${f%/cmdline}" | tr -d '/proc/'
            return
        fi
    done
}

_shutdown() {
    local pid
    pid=$(_get_urbackup_pid)
    if [ -n "$pid" ]; then
        echo "[UrBackup] Wird beendet (PID ${pid})..."
        kill -SIGTERM "$pid" 2>/dev/null || true
        # Warten bis Prozess beendet
        for i in $(seq 1 15); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 1
        done
    fi
    wait "$FILTER_PID" 2>/dev/null || true
    echo "[UrBackup] Beendet."
}

trap _shutdown SIGINT SIGTERM

wait "$FILTER_PID"
