FROM ubuntu:18.04

MAINTAINER t3kit

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    # Install git
    git \
    # Install apache
    apache2 \
    # Install php 7.2
    libapache2-mod-php7.2 \
    php7.0-cli \
    php7.0-json \
    php7.0-curl \
    php7.0-fpm \
    php7.0-gd \
    php7.0-ldap \
    php7.0-mbstring \
    php7.0-mysql \
    php7.0-soap \
    php7.0-sqlite3 \
    php7.0-xml \
    php7.0-zip \
    php7.0-intl \
    php-imagick \
    # Install tools
    openssl \
    nano \
    graphicsmagick \
    imagemagick \
    ghostscript \
    mysql-client \
    iputils-ping \
    locales \
    sqlite3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git subversion make g++ python2.7 curl php7.0-cli php7.0-dev chrpath wget bzip2 && \
    ln -s /usr/bin/python2.7 /usr/bin/python && \
    \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /tmp/depot_tools && \
    export PATH="$PATH:/tmp/depot_tools" && \
    \
    cd /usr/local/src && fetch v8 && cd v8 && \
    git checkout 5.4.500.40 && gclient sync && \
    export GYPFLAGS="-Dv8_use_external_startup_data=0" && \
    export GYPFLAGS="${GYPFLAGS} -Dlinux_use_bundled_gold=0" && \
    make native library=shared snapshot=on -j4 && \
    \
    mkdir -p /usr/local/lib && \
    cp /usr/local/src/v8/out/native/lib.target/lib*.so /usr/local/lib && \
    echo "create /usr/local/lib/libv8_libplatform.a\naddlib out/native/obj.target/src/libv8_libplatform.a\nsave\nend" | ar -M && \
    cp -R /usr/local/src/v8/include /usr/local && \
    chrpath -r '$ORIGIN' /usr/local/lib/libv8.so && \
    \
    git clone https://github.com/phpv8/v8js.git /usr/local/src/v8js && \
    cd /usr/local/src/v8js && phpize && ./configure --with-v8js=/usr/local && \
    export NO_INTERACTION=1 && make all -j4 && make test install && \
    \
    echo extension=v8js.so > /etc/php/7.0/cli/conf.d/99-v8js.ini && \
    \
    cd /tmp && \
    rm -rf /tmp/depot_tools /usr/local/src/v8 /usr/local/src/v8js && \
    apt-get remove -y subversion make g++ python2.7 curl php7.0-dev chrpath wget bzip2 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set locales
RUN locale-gen en_US.UTF-8 en_GB.UTF-8 de_DE.UTF-8 es_ES.UTF-8 fr_FR.UTF-8 it_IT.UTF-8 km_KH sv_SE.UTF-8 fi_FI.UTF-8

RUN a2enmod rewrite expires

# Configure PHP
ADD typo3.php.ini /etc/php/7.0/apache2/conf.d/

# Configure vhost
ADD typo3.default.conf /etc/apache2/sites-enabled/000-default.conf

EXPOSE 80 443

WORKDIR /var/www/html

RUN rm index.html

CMD ["apache2ctl", "-D", "FOREGROUND"]