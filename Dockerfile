FROM php:8.3.14-fpm-alpine3.20

ENV TZ=America/Sao_Paulo

RUN apk add --no-cache \
  busybox-extras \
  nano \
  tzdata \
  bash \
  unzip \
  make \
  libpng-dev \
  zlib-dev \
  libzip-dev \
  autoconf \
  gcc \
  g++ \
  linux-headers \
  && pecl install xdebug \
  && docker-php-ext-enable xdebug \
  && docker-php-ext-install pdo pdo_mysql gd zip

# Configurações adicionais de PHP (timezone)
RUN echo "date.timezone = ${TZ}" > /usr/local/etc/php/conf.d/99-timezone.ini \
  && mkdir -p /var/run/php && chown www-data:www-data /var/run/php

RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && \
  echo $TZ > /etc/timezone

# Configuração do Xdebug
RUN echo "zend_extension=xdebug" > /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/99-xdebug.ini  \
  && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.idekey=VSCODE" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.log_level=7" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.log=/tmp/xdebug.log" >> /usr/local/etc/php/conf.d/99-xdebug.ini

WORKDIR /var/www/html

EXPOSE 9000

CMD ["php-fpm"]