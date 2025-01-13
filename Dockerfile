
FROM curlimages/curl:8.6.0 AS cacert
FROM phpswoole/swoole:5.0.3-php8.0-alpine

RUN apk --update --no-cache add bind-tools
COPY --from=cacert /etc/ssl /root/ssl
RUN mv /etc/ssl/openssl.cnf* /root/ssl && rm -rf /etc/ssl && mv /root/ssl /etc/ssl \
    && update-ca-certificates \
    && pecl channel-update pecl.php.net

RUN docker-php-ext-install pcntl && docker-php-ext-configure pcntl --enable-pcntl
RUN apk add --update --no-cache libzip-dev libpng-dev git postgresql-dev
RUN docker-php-ext-install mysqli pdo pdo_mysql zip gd bcmath exif pgsql pdo_pgsql intl

ARG RUNTIME_ENVFILE=.env.example
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TZ=Asia/Taipei

RUN apk add --update --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime && \
    echo "$TZ" | tee /etc/timezone && \
    apk del tzdata

WORKDIR /var/www

COPY . .

RUN composer install

RUN mv ${RUNTIME_ENVFILE} .env

COPY ./dockerconfig-swoole/php.ini /usr/local/etc/php/conf.d/
COPY ./dockerconfig-swoole/entrypoint.sh /etc/app/entrypoint.sh

ENTRYPOINT ["/bin/sh", "/etc/app/entrypoint.sh"]
