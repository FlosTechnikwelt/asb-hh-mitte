# ASB Hamburg-Mitte auf Grav

Die Website läuft vollständig mit **Grav 2.1** und benötigt keine Datenbank.
Das aktive Theme liegt unter `grav/user/themes/asb-hh-mitte/`.

## Lokal starten

Voraussetzung ist Docker mit Docker Compose.

```sh
docker compose up --build -d
```

Die Website ist anschließend unter <http://localhost> erreichbar. Wird Port 80
bereits verwendet, kann ein anderer Port gesetzt werden:

```sh
GRAV_PORT=8080 docker compose up --build -d
```

Beim ersten Aufruf von `/admin` führt Grav durch das Anlegen des
Administrationskontos. Seiten, Konfiguration, Konten, Backups und Logs liegen in
Docker-Volumes und bleiben bei einem normalen Container-Neustart erhalten.

## Automatische Updates

Bei jedem Containerstart prüft `docker/grav-entrypoint.sh` zuerst Grav Core und
danach alle installierten Plugins auf Updates. Verfügbare Updates werden
automatisch und nicht-interaktiv installiert. Schlägt die Prüfung wegen eines
vorübergehenden Netzwerkfehlers fehl, wird eine Warnung in die Container-Logs
geschrieben und die Website trotzdem gestartet.

Das Zeitlimit für den Download eines Grav-Core-Updates beträgt standardmäßig
120 Sekunden und kann bei Bedarf über `GRAV_UPDATE_TIMEOUT` geändert werden.

## Struktur

- `grav/user/config/`: Grav-System- und Website-Konfiguration
- `grav/user/pages/`: Markdown-Inhalte
- `grav/user/themes/asb-hh-mitte/`: Twig-Templates und ASB-Assets

Die verwendete Grav-Version ist in `docker-compose.yaml` auf `2.1.8` festgelegt
und kann über `GRAV_VERSION` kontrolliert aktualisiert werden.
