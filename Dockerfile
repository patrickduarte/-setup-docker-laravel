FROM php:7.4-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip 


# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd 

# Install Addition PHP extensions for work laravel projetc

RUN apt-get update && \
    apt-get install -y libzip-dev  && \
 docker-php-ext-install zip

RUN docker-php-ext-install soap 

RUN apt-get install -y \
        libicu-dev \
    && docker-php-ext-install intl

RUN docker-php-ext-enable opcache  && \
    docker-php-ext-install calendar && \
    docker-php-ext-install bcmath

RUN apt-get update && apt-get install -y libmcrypt-dev \
    && pecl install mcrypt-1.0.3 \
    && docker-php-ext-enable mcrypt

RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y libxml2-dev && \
   docker-php-ext-install -j$(nproc) xmlrpc

RUN apt-get install -y \
        libmcrypt-dev \
    && docker-php-ext-install session

RUN apt-get install -y \
        libssl-dev \
    && docker-php-ext-install ftp 


RUN \ 
apt-get update && \
apt-get install libldap2-dev -y && \
rm -rf /var/lib/apt/lists/* && \
docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
docker-php-ext-install ldap


# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install and configure Oracle Client extension

RUN mkdir /opt/oracle && \
    apt-get update && \
    apt-get install -y libaio1 unzip wget && \
    cd /tmp && \
    wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sqlplus-linux.x64-19.6.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-19.6.0.0.0dbru.zip -d /opt/oracle && \
    unzip instantclient-sqlplus-linux.x64-19.6.0.0.0dbru.zip -d /opt/oracle && \
    unzip instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip -d /opt/oracle && \
    rm -f instantclient-basic-linux.x64-19.6.0.0.0dbru.zip && \
    rm -f instantclient-sqlplus-linux.x64-19.6.0.0.0dbru.zip && \
    rm -f instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip && \
    echo /opt/oracle/instantclient_19_6 > /etc/ld.so.conf.d/oracle-instantclient && \
    ldconfig

# Set enviroment variable to oracle client work fine

ENV PATH=$PATH:/opt/oracle/instantclient_19_6 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/oracle/instantclient_19_6

# Install and configure OCI8 lib to PHP works with oracle client

RUN echo 'instantclient,/opt/oracle/instantclient_19_6' | pecl install oci8-2.2.0 \
    && docker-php-ext-enable oci8 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_19_6 \
    && docker-php-ext-install pdo_oci


# Install xdebug
RUN pecl install xdebug-2.9.2 \
    && docker-php-ext-enable xdebug 

ADD xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Create system user to run Composer and Artisan Commands

RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/ .composer && \
    chown -R $user:$user /home/$user



# Set working directory
WORKDIR /var/www

USER $user

