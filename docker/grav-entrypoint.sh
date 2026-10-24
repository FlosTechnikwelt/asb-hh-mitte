#!/bin/sh

set -u

cd /var/www/html

echo "[grav-update] Prüfe Grav Core auf Updates ..."
if runuser -u www-data -- php bin/gpm self-upgrade \
    --force \
    --all-yes \
    --no-interaction \
    --timeout="${GRAV_UPDATE_TIMEOUT:-120}"; then
    echo "[grav-update] Grav Core ist aktuell."
else
    echo "[grav-update] WARNUNG: Grav Core konnte nicht aktualisiert werden; der Start wird fortgesetzt." >&2
fi

echo "[grav-update] Prüfe alle Plugins auf Updates ..."
if runuser -u www-data -- php bin/gpm update \
    --plugins \
    --force \
    --all-yes \
    --no-interaction; then
    echo "[grav-update] Alle Plugins sind aktuell."
else
    echo "[grav-update] WARNUNG: Plugins konnten nicht vollständig aktualisiert werden; der Start wird fortgesetzt." >&2
fi

runuser -u www-data -- php bin/grav cache --quiet || true

if [ "$#" -eq 0 ]; then
    set -- apache2-foreground
fi

if [ "$1" = "apache2-foreground" ]; then
    cron_path='PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    cron_line='* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1'
    temporary_crontab="$(mktemp)"

    crontab -u www-data -l 2>/dev/null \
        | grep -Fv 'bin/grav scheduler' > "$temporary_crontab" || true
    if ! grep -Fqx "$cron_path" "$temporary_crontab"; then
        printf '%s\n' "$cron_path" >> "$temporary_crontab"
    fi
    printf '%s\n' "$cron_line" >> "$temporary_crontab"
    crontab -u www-data "$temporary_crontab"
    rm -f "$temporary_crontab"

    echo "[grav-scheduler] Crontab für www-data installiert; starte Cron-Daemon."
    cron -f &
    cron_pid="$!"

    docker-php-entrypoint "$@" &
    apache_pid="$!"

    shutdown() {
        trap - INT TERM
        kill -TERM "$apache_pid" "$cron_pid" 2>/dev/null || true
        wait "$apache_pid" "$cron_pid" 2>/dev/null || true
        exit 0
    }

    trap shutdown INT TERM

    while kill -0 "$apache_pid" 2>/dev/null && kill -0 "$cron_pid" 2>/dev/null; do
        sleep 5 &
        wait "$!"
    done

    echo "[grav-scheduler] WARNUNG: Apache oder Cron wurde unerwartet beendet; Container wird neu gestartet." >&2
    kill -TERM "$apache_pid" "$cron_pid" 2>/dev/null || true
    wait "$apache_pid" "$cron_pid" 2>/dev/null || true
    exit 1
fi

exec docker-php-entrypoint "$@"
