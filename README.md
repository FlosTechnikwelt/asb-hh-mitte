# ASB Hamburg-Mitte auf Grav

Die Website läuft vollständig mit **Grav 2.1** und benötigt keine Datenbank.
Das aktive Theme liegt unter `grav/user/themes/asb-hh-mitte/`.

## Lokal starten

Voraussetzung ist Docker mit Docker Compose.

```sh
docker compose up --build -d
```

Die Website ist anschließend unter <http://localhost:3097> erreichbar. Wird Port 3097
bereits verwendet, kann ein anderer Port gesetzt werden:

```sh
GRAV_PORT=8080 docker compose up --build -d
```

Beim ersten Aufruf von `/admin` führt Grav durch das Anlegen des
Administrationskontos. Seiten einschließlich ihrer Bilder, die zentrale
Mediathek, allgemeine Uploads, Plugins, Konfiguration, Konten, Backups und Logs
liegen in Docker-Volumes und bleiben auch beim Neuerstellen des Containers
erhalten.

## Scheduler

Der Grav-Container betreibt neben Apache einen Cron-Daemon, der den Grav
Scheduler jede Minute als Benutzer `www-data` aufruft. Damit werden aktivierte
Grav-Jobs wie Cache-Bereinigung und Backups automatisch zu ihren konfigurierten
Zeiten ausgeführt. Da Cron im selben Container läuft, verwendet er denselben
Grav-Core, dieselben Plugins und denselben Cache. Die Grav-Administration kann
den installierten Cron-Eintrag ebenfalls direkt erkennen.

Der Scheduler-Status und die Ausführungszeiten lassen sich mit folgenden
Befehlen kontrollieren:

```sh
docker compose exec -u www-data grav crontab -l
docker compose exec -u www-data grav php bin/grav scheduler -d
```

## Automatische Updates

Bei jedem Containerstart prüft `docker/grav-entrypoint.sh` zuerst Grav Core und
danach alle installierten Plugins auf Updates. Verfügbare Updates werden
automatisch und nicht-interaktiv installiert. Schlägt die Prüfung wegen eines
vorübergehenden Netzwerkfehlers fehl, wird eine Warnung in die Container-Logs
geschrieben und die Website trotzdem gestartet.

Das Zeitlimit für den Download eines Grav-Core-Updates beträgt standardmäßig
120 Sekunden und kann bei Bedarf über `GRAV_UPDATE_TIMEOUT` geändert werden.

## PHP

Das Image verwendet standardmäßig die aktuelle PHP-8.5-Reihe und enthält
neben den erforderlichen Modulen auch die empfohlenen Linux-Erweiterungen
`yaml`, `apcu`, `memcache`, `memcached` und `redis`. `curl` ist ebenfalls aktiv.
Die PHP-Reihe kann beim Build bei Bedarf über `PHP_VERSION` gesetzt werden.

Da das letzte stabile PECL-Paket von `memcache` PHP 8.5 noch nicht unterstützt,
wird eine fest gepinnte Revision aus dem offiziellen `pecl-memcache`-Repository
gebaut.

`WinCache` wird nicht installiert, weil diese Erweiterung ausschließlich für
PHP auf Windows beziehungsweise Windows Server vorgesehen ist.

## Struktur

- `grav/user/config/`: Grav-System- und Website-Konfiguration
- `grav/user/assets/`: allgemeine Upload-Ziele von Plugins und Blueprints
- `grav/user/media/`: zentrale Grav-Mediathek und allgemeine Uploads
- `grav/user/pages/`: Markdown-Inhalte
- `grav/user/plugins/`: installierte und aktualisierte Grav-Plugins
- `grav/user/themes/asb-hh-mitte/`: Twig-Templates und ASB-Assets

Die Basisversion von Grav ist in `docker-compose.yml` auf `2.1.8` festgelegt
und kann über `GRAV_VERSION` kontrolliert aktualisiert werden.
