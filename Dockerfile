ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-apache

ARG GRAV_VERSION=2.1.8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" exif gd intl zip \
    && a2enmod expires headers rewrite \
    && sed -ri 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
    && printf 'ServerName localhost\n' > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    && curl -fsSL "https://github.com/getgrav/grav/releases/download/${GRAV_VERSION}/grav-admin-v${GRAV_VERSION}.zip" -o /tmp/grav.zip \
    && unzip -q /tmp/grav.zip -d /tmp \
    && cp -a /tmp/grav-admin/. /var/www/html/ \
    && rm -rf /tmp/grav.zip /tmp/grav-admin /var/www/html/user/pages /var/www/html/user/themes/quark2 \
    && rm -rf /var/lib/apt/lists/*

COPY grav/user/ /var/www/html/user/
COPY docker/grav-entrypoint.sh /usr/local/bin/grav-entrypoint

RUN mkdir -p /var/www/html/backup /var/www/html/cache /var/www/html/logs /var/www/html/tmp \
    && chown -R www-data:www-data /var/www/html \
    && chmod 0755 /usr/local/bin/grav-entrypoint

WORKDIR /var/www/html

ENTRYPOINT ["grav-entrypoint"]
CMD ["apache2-foreground"]
