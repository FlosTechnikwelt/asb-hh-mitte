ARG PHP_VERSION=8.5
FROM php:${PHP_VERSION}-apache

ARG GRAV_VERSION=2.1.8
ARG APCU_VERSION=5.1.28
ARG MEMCACHE_COMMIT=ac8e8c521a18aae14c8f2859694536ead304ce97
ARG MEMCACHED_VERSION=3.4.0
ARG REDIS_VERSION=6.3.0
ARG YAML_VERSION=2.3.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cron \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libmemcached-dev \
        libpng-dev \
        libsasl2-dev \
        libyaml-dev \
        libzip-dev \
        unzip \
        zlib1g-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" exif gd intl zip \
    && curl -fsSL "https://github.com/websupport-sk/pecl-memcache/archive/${MEMCACHE_COMMIT}.tar.gz" -o /tmp/memcache.tar.gz \
    && mkdir /tmp/memcache \
    && tar -xzf /tmp/memcache.tar.gz --strip-components=1 -C /tmp/memcache \
    && cd /tmp/memcache \
    && phpize \
    && ./configure --enable-memcache-session \
    && make -j"$(nproc)" \
    && make install \
    && cd /var/www/html \
    && pecl install \
        "apcu-${APCU_VERSION}" \
        "memcached-${MEMCACHED_VERSION}" \
        "redis-${REDIS_VERSION}" \
        "yaml-${YAML_VERSION}" \
    && docker-php-ext-enable apcu memcache memcached redis yaml \
    && a2enmod expires headers rewrite \
    && sed -ri 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
    && printf 'ServerName localhost\n' > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    && curl -fsSL "https://github.com/getgrav/grav/releases/download/${GRAV_VERSION}/grav-admin-v${GRAV_VERSION}.zip" -o /tmp/grav.zip \
    && unzip -q /tmp/grav.zip -d /tmp \
    && cp -a /tmp/grav-admin/. /var/www/html/ \
    && rm -rf /tmp/grav.zip /tmp/grav-admin /tmp/memcache /tmp/memcache.tar.gz /tmp/pear /var/www/html/user/pages /var/www/html/user/themes/quark2 \
    && rm -rf /var/lib/apt/lists/*

RUN php -r 'foreach (["yaml", "apcu", "memcache", "memcached", "redis", "curl"] as $extension) { if (!extension_loaded($extension)) { fwrite(STDERR, "Missing PHP extension: {$extension}\n"); exit(1); } }'

COPY grav/user/ /var/www/html/user/
COPY docker/grav-entrypoint.sh /usr/local/bin/grav-entrypoint

RUN mkdir -p /var/www/html/backup /var/www/html/cache /var/www/html/logs /var/www/html/tmp \
        /var/www/html/user/assets /var/www/html/user/media /var/www/html/user/plugins \
    && chown -R www-data:www-data /var/www/html \
    && chmod 0755 /usr/local/bin/grav-entrypoint

WORKDIR /var/www/html

ENTRYPOINT ["grav-entrypoint"]
CMD ["apache2-foreground"]
