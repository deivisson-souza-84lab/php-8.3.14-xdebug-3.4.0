FROM alpine:3.20.3

ENV PHP_VERSION=8.3.14 \
  PHP_SHA256=58b4cb9019bf70c0cbcdb814c7df79b9065059d14cf7dbf48d971f8e56ae9be7 \
  PHP_INI_DIR=/usr/local/etc/php \
  XDEBUG_VERSION=3.4.0 \
  TZ=America/Sao_Paulo

RUN addgroup -g 33 -S www-data || true \
  && adduser -D -G www-data -u 33 -S www-data

# Instala as dependências para compilar extensões PHP
RUN apk add --no-cache \
  busybox-extras \
  nano \
  tzdata \
  bash \
  build-base \
  curl \
  tar \
  xz \
  autoconf \
  automake \
  bison \
  re2c \
  libxml2-dev \
  oniguruma-dev \
  libjpeg-turbo-dev \
  libzip-dev \
  zlib-dev \
  openssl-dev \
  sqlite-dev \
  readline-dev \
  freetype-dev \
  icu-dev \
  libedit-dev \
  curl-dev \
  linux-headers \
  libxslt-dev \
  pcre-dev \
  php83-pear \
  php83-openssl \
  php83-dev \
  ca-certificates

# Configura o fuso horário
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && \
  echo $TZ > /etc/timezone

# Baixa e instala o PHP
RUN curl -fsSL https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz -o php.tar.xz \
  && echo "$PHP_SHA256  php.tar.xz" | sha256sum -c - \
  && mkdir -p /usr/src/php \
  && tar -xJf php.tar.xz -C /usr/src/php --strip-components=1 \
  && rm php.tar.xz

# Compila e instala o PHP
RUN cd /usr/src/php \
  && ./configure --prefix=/usr/local \
  --with-config-file-path=$PHP_INI_DIR \
  --with-config-file-scan-dir=$PHP_INI_DIR/conf.d \
  --with-openssl \
  --with-zlib \
  --with-curl \
  --with-mysqli \
  --with-pdo-mysql \
  --with-xsl \
  --with-bz2 \
  --with-jpeg-dir=/usr/include \
  --with-png-dir=/usr/include \
  --with-freetype-dir=/usr/include \
  --with-icu-dir=/usr \
  --enable-fpm \
  --enable-mbstring \
  --enable-soap \
  --enable-sockets \
  --enable-intl \
  && make -j"$(nproc)" \
  && make install \
  && make clean

# Baixa e instala o Xdebug
RUN curl -fsSL https://xdebug.org/files/xdebug-${XDEBUG_VERSION}.tgz -o /tmp/xdebug.tgz \
  && tar -xvzf /tmp/xdebug.tgz -C /tmp \
  && cd /tmp/xdebug-${XDEBUG_VERSION} \
  && phpize \
  && ./configure \
  && make -j"$(nproc)" \
  && make install \
  && cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
# && rm -rf /tmp/xdebug*

# Configurações do PHP-FPM
RUN mkdir -p /usr/local/etc/php/conf.d \
  && cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf \
  && cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf \
  && echo "error_log = /var/log/php-fpm.log" > /usr/local/etc/php/conf.d/99-error_log.ini \
  && echo "include=/usr/local/etc/php-fpm.d/*.conf" >> /usr/local/etc/php-fpm.conf \
  && echo "listen = 0.0.0.0:9000" >> /usr/local/etc/php-fpm.conf \
  && sed -i 's#user = nobody#user = www-data#' /usr/local/etc/php-fpm.d/www.conf \
  && sed -i 's#group = nobody#group = www-data#' /usr/local/etc/php-fpm.d/www.conf

# Configurações adicionais de PHP (timezone)
RUN echo "date.timezone = ${TZ}" > /usr/local/etc/php/conf.d/99-timezone.ini \
  && mkdir -p /var/run/php && chown www-data:www-data /var/run/php

# Configuração do Xdebug
RUN echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20230831/xdebug.so" > /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  # && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/99-xdebug.ini  \
  && echo "xdebug.client_host=192.168.1.157" >> /usr/local/etc/php/conf.d/99-xdebug.ini  \
  && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.idekey=VSCODE" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.client_timeout = 10000" >> /usr/local/etc/php/conf.d/99-xdebug.ini \
  && echo "xdebug.log=/tmp/xdebug.log" >> /usr/local/etc/php/conf.d/99-xdebug.ini

WORKDIR /var/www/html

EXPOSE 9000

CMD ["php-fpm", "-F"]