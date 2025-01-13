
FROM curlimages/curl:8.6.0 AS cacert
FROM phpswoole/swoole:5.0.3-php8.0-alpine

# ENV COMPOSER_ALLOW_SUPERUSER=1

# Use curl cert
# Ref https://stackoverflow.com/a/76605306
# Ref https://github.com/lazyfrosch/docker-icingaweb2/issues/1
# Use HK mirror
RUN sed -i -e 's/dl-cdn.alpinelinux.org/mirror.xtom.com.hk/g' /etc/apk/repositories
RUN apk --update --no-cache add bind-tools
COPY --from=cacert /etc/ssl /root/ssl
RUN mv /etc/ssl/openssl.cnf* /root/ssl && rm -rf /etc/ssl && mv /root/ssl /etc/ssl \
    && update-ca-certificates \
    && pecl channel-update pecl.php.net

RUN docker-php-ext-install pcntl && docker-php-ext-configure pcntl --enable-pcntl
RUN apk add --update --no-cache libzip-dev libpng-dev git postgresql-dev
RUN docker-php-ext-install mysqli pdo pdo_mysql zip gd bcmath exif pgsql pdo_pgsql intl
# RUN docker-php-ext-enable pdo_mysql pdo_pgsql pgsql pdo


ARG RUNTIME_ENVFILE=.env.example
ARG SUPERVISORD_GO_VER=0.7.3
ARG SUPERVISORD_GO_OS=Linux_64-bit
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
COPY ./dockerconfig-swoole/supervisord.conf /etc/app/supervisord.conf
RUN wget https://github.com/ochinchina/supervisord/releases/download/v${SUPERVISORD_GO_VER}/supervisord_${SUPERVISORD_GO_VER}_${SUPERVISORD_GO_OS}.tar.gz && \
    tar zxvf ./supervisord_${SUPERVISORD_GO_VER}_${SUPERVISORD_GO_OS}.tar.gz && \
    mv supervisord_${SUPERVISORD_GO_VER}_${SUPERVISORD_GO_OS}/supervisord /bin && \
    rm -rf supervisord_${SUPERVISORD_GO_VER}_${SUPERVISORD_GO_OS}*

ENTRYPOINT ["/bin/sh", "/etc/app/entrypoint.sh"]
