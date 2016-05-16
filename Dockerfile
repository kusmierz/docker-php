FROM php:7.0.6-fpm

MAINTAINER Varya <contact@varya.pro>

# Configure timezone and locale
RUN set -xe \
    && apt-get update \
    && apt-get install --no-install-recommends -y locales \
    && rm -rf /var/lib/apt/lists/*
ENV LANG pl_PL.UTF-8
ENV LANGUAGE pl_PL:pl
ENV LC_ALL pl_PL.UTF-8
RUN set -xe \
    && echo 'Europe/Warsaw' > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata \
    && echo 'pl_PL ISO-8859-2' >> /etc/locale.gen \
    && echo 'pl_PL.UTF-8 UTF-8' >> /etc/locale.gen \
    && locale-gen en_US en_US.UTF-8 pl_PL pl_PL.UTF-8 \
    && dpkg-reconfigure -f noninteractive locales \
    && ln -sf /usr/share/zoneinfo/Poland /etc/localtime

RUN set -xe \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        zip unzip \
        git \
        libpcre3-dev \
        libssl-dev \
        libicu-dev \
        libmcrypt-dev \
        libicu-dev \
        libjpeg-dev \
        libpng-dev \
        libgmp-dev \
        libfreetype6-dev \
        python \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    # Common php extensions
    && docker-php-ext-install opcache mcrypt mbstring gettext intl iconv gmp \
    && docker-php-ext-configure gd -with-freetype-dir=/usr/include/ -with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && apt-get purge --auto-remove -y \
        libpng-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libcurl3-dev \
        libxml2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Redis extension
# for php56: RUN pecl install redis && docker-php-ext-enable redis
# TODO see also https://github.com/phpredis/phpredis/pull/759
RUN set -xe \
    && cd /tmp \
    && git clone https://github.com/phpredis/phpredis.git \
    && cd phpredis \
    && git checkout php7 \
    && phpize \
    && ./configure \
    && make && make install \
    && cd .. \
    && rm -rf phpredis \
    && docker-php-ext-enable redis

# Postgresql support
RUN set -xe \
    && apt-get update \
    && apt-get install --no-install-recommends -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/include/postgresql/ \
    && docker-php-ext-install pgsql pdo_pgsql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ImageMagick support
RUN set -xe \
    && apt-get update \
    && apt-get install --no-install-recommends -y libmagickwand-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# composer.phar
ADD https://getcomposer.org/composer.phar /usr/local/bin/composer
RUN chmod a+xr /usr/local/bin/composer

RUN pecl install xdebug && docker-php-ext-enable xdebug

EXPOSE 9000

CMD ["php-fpm"]
