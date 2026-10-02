FROM quay.io/keycloak/keycloak:26.7.2

COPY --chown=1000:0 --chmod=0755 keycloak/start-asb-keycloak.sh /opt/keycloak/bin/start-asb-keycloak.sh
COPY --chown=1000:0 keycloak/import /opt/keycloak/data/import
COPY --chown=1000:0 keycloak/themes/asb-hh-mitte /opt/keycloak/themes/asb-hh-mitte
COPY --chown=1000:0 keycloak/branding/logo-asb-hh-mitte.svg /opt/keycloak/themes/asb-hh-mitte/login/resources/img/logo-asb.svg
COPY --chown=1000:0 keycloak/branding/logo-asb-hh-mitte.svg /opt/keycloak/themes/asb-hh-mitte/account/resources/logo-asb.svg
