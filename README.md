# urbackup-ptero

Pterodactyl Wings-kompatibles Docker-Image für [UrBackup Server](https://www.urbackup.org/).

## Problem & Lösung

UrBackup läuft standardmäßig als `root`. Pterodactyl Wings erzwingt `uid=999`.  
Dieses Image löst das durch:

- `uid=999` für den `urbackup`-User (Wings-kompatibel)
- `/etc/default/urbackupsrv` zur Laufzeit schreibbar → Ports per Env-Variable konfigurierbar
- Web-Assets mit korrekten Lese-Rechten

## Image

```
ghcr.io/pavl21/urbackup-ptero:latest
```

## Env-Variablen

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `HTTP_PORT` | `55414` | Web-Interface Port |
| `INTERNET_PORT` | `55415` | Backup-Client Port |
| `FASTCGI_PORT` | `55413` | FastCGI Port (optional) |
| `BACKUP_PATH` | `/home/container/backups` | Backup-Speicherort |
| `LOGLEVEL` | `warn` | Log-Level: debug/info/warn/error |
| `TZ` | `Europe/Berlin` | Zeitzone |

## Pterodactyl-Allocations

Mindestens 2 Ports zuweisen:

| Allocation | Variable | Funktion |
|------------|----------|----------|
| Primär (z.B. 55416) | `HTTP_PORT={{SERVER_PORT}}` | Web-Oberfläche |
| Sekundär (z.B. 55417) | `INTERNET_PORT=55417` | Backup-Clients |

## Ports

| Port | Protokoll | Funktion |
|------|-----------|----------|
| 55414 (Standard) | TCP | Web-Interface |
| 55415 (Standard) | TCP | Backup-Client-Verbindungen |
| 55413 (Standard) | TCP | FastCGI |
| 35623 | UDP | LAN-Auto-Erkennung |

## Standard-Login

```
Benutzer: admin
Passwort: admin
```

**Nach dem ersten Login sofort ändern!**
