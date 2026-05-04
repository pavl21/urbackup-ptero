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

# Backup-Verzeichnis anlegen
mkdir -p "$BACKUP_PATH"
echo -n "$BACKUP_PATH" > /var/urbackup/backupfolder

# Port-Konfiguration aus Env-Variablen schreiben
cat > /etc/default/urbackupsrv << CONF
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

echo "[INFO] Konfiguration geschrieben"
echo "[INFO]   HTTP_PORT=${HTTP_PORT}"
echo "[INFO]   INTERNET_PORT=${INTERNET_PORT}"
echo "[INFO] Starte UrBackup-Server..."
echo ""

exec urbackupsrv "$@" --config /etc/default/urbackupsrv
