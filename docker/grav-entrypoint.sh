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

exec docker-php-entrypoint "$@"
