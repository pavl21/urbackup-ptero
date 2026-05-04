#!/bin/bash
set -e

HTTP_PORT="${HTTP_PORT:-55414}"
INTERNET_PORT="${INTERNET_PORT:-55415}"
FASTCGI_PORT="${FASTCGI_PORT:-55413}"
BACKUP_PATH="${BACKUP_PATH:-/home/container/backups}"
LOGLEVEL="${LOGLEVEL:-warn}"
TZ="${TZ:-Europe/Berlin}"

echo "============================================"
echo "  UrBackup Server - Pterodactyl Edition"
echo "============================================"
echo ""
echo "  Web-Oberflaeche : http://SERVER-IP:${HTTP_PORT}"
echo "  Backup-Clients  : Port ${INTERNET_PORT}/TCP"
echo "  LAN-Erkennung   : Port 35623/UDP (falls zugewiesen)"
echo ""
echo "  Standard-Login  : admin / admin"
echo "  WICHTIG: Passwort nach erstem Login aendern!"
echo ""
echo "  Backup-Pfad     : ${BACKUP_PATH}"
echo "  Zeitzone        : ${TZ}"
echo "  Log-Level       : ${LOGLEVEL}"
echo "============================================"
echo ""

# Backup-Verzeichnis anlegen (Pterodactyl mounted /home/container automatisch)
mkdir -p "$BACKUP_PATH" 2>/dev/null || true
echo -n "$BACKUP_PATH" > /var/urbackup/backupfolder

# Config in schreibbares Volume schreiben (/var/urbackup ist Docker-Volume)
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

echo "[INFO] Konfiguration geschrieben nach ${CONFIG_FILE}"
echo "[INFO]   HTTP_PORT=${HTTP_PORT}"
echo "[INFO]   INTERNET_PORT=${INTERNET_PORT}"
echo "[INFO] Starte UrBackup-Server..."
echo ""

exec urbackupsrv "$@" --config "${CONFIG_FILE}"
