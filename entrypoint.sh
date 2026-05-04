#!/bin/bash
set -eo pipefail

HTTP_PORT="${HTTP_PORT:-55414}"
INTERNET_PORT="${INTERNET_PORT:-55415}"
FASTCGI_PORT="${FASTCGI_PORT:-55413}"
BACKUP_PATH="${BACKUP_PATH:-/home/container/backups}"
LOGLEVEL="${LOGLEVEL:-warn}"
TZ="${TZ:-Europe/Berlin}"

echo "============================================"
echo "  UrBackup Server - Pterodactyl Edition"
echo "============================================"
echo "  Web-Oberflaeche : http://SERVER-IP:${HTTP_PORT}"
echo "  Backup-Clients  : Port ${INTERNET_PORT}/TCP"
echo "  LAN-Erkennung   : Port 35623/UDP (optional)"
echo "  Standard-Login  : admin / admin"
echo "  Backup-Pfad     : ${BACKUP_PATH}"
echo "  Zeitzone        : ${TZ}"
echo "============================================"
echo ""

# Backup-Verzeichnis anlegen (Pterodactyl mounted /home/container)
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

echo "[START] HTTP_PORT=${HTTP_PORT} | INTERNET_PORT=${INTERNET_PORT} | LOGLEVEL=${LOGLEVEL}"
echo ""

# urbackupsrv starten — bekannte harmlose Meldungen herausfiltern
urbackupsrv "$@" --config "${CONFIG_FILE}" 2>&1 | \
  grep --line-buffered -Ev \
    "^Raising nice-ceiling|^Cannot become root user|WARNING: Upgrading database to version [0-9]+" | \
  sed --unbuffered \
    -e 's/WARNING: Upgrading\.\.\./[INFO] Datenbank-Migration wird durchgefuehrt.../' \
    -e 's/WARNING: Done\./[INFO] Datenbank-Migration abgeschlossen./' \
    -e 's/WARNING: Creating file entry index.*/[INFO] Datei-Index wird erstellt.../'
