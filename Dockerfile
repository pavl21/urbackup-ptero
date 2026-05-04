FROM uroni/urbackup-server:latest

LABEL maintainer="schwarzpaul123@gmail.com"
LABEL description="UrBackup Server kompatibel mit Pterodactyl Wings (uid=999)"

# Wings erwartet uid=999, gid=989
# Config-Datei schreibbar fuer uid=999 (Port-Konfiguration zur Laufzeit)
# Web-Assets lesbar fuer uid=999
RUN usermod -u 999 -o urbackup && \
    groupmod -g 989 -o urbackup && \
    chmod -R a+rX /usr/share/urbackup && \
    chown -R urbackup:urbackup /var/urbackup /backups

COPY entrypoint.sh /usr/bin/entrypoint-ptero.sh
RUN chmod +x /usr/bin/entrypoint-ptero.sh

EXPOSE 55413/tcp 55414/tcp 55415/tcp 35623/udp

ENTRYPOINT ["/usr/bin/entrypoint-ptero.sh"]
CMD ["run"]
