ARG PHP_VERSION=8.3

FROM thecodingmachine/php:${PHP_VERSION}-v4-apache-node20

# Enable extensions
ENV PHP_EXTENSION_GD=1
ENV PHP_EXTENSION_GMP=1
ENV PHP_EXTENSION_INTL=1
ENV PHP_EXTENSION_LDAP=1
ENV PHP_EXTENSION_PGSQL=1
ENV PHP_EXTENSION_PDO_PGSQL=1
ENV PHP_EXTENSION_PDO_SQLITE=1
ENV PHP_EXTENSION_SQLITE3=1
ENV PHP_EXTENSION_XDEBUG=1
ENV PHP_EXTENSION_IMAGICK=1

# PHP ini variables
ENV PHP_INI_XDEBUG__CLIENT_HOST=127.0.0.1 
# !Important for step debugging directly in container with vscode devcontainer
ENV PHP_INI_XDEBUG__CLIENT_PORT=9003
ENV PHP_INI_XDEBUG__MODE=coverage,debug,profile,trace
# ENV PHP_INI_XDEBUG__START_WITH_REQUEST=yes
ENV PHP_INI_UPLOAD_MAX_FILESIZE=200M
ENV PHP_INI_POST_MAX_SIZE=200M

# Install
RUN sudo apt-get update
RUN sudo apt-get install -y mariadb-client
RUN sudo apt-get install -y postgresql-client
RUN sudo apt-get install -y sqlite3
RUN sudo apt-get install -y graphviz python
RUN sudo apt-get install -y build-essential
RUN sudo apt-get install -y rsync
RUN sudo apt-get install -y zip
RUN sudo apt-get install -y unzip
RUN sudo apt-get install -y php-pear
RUN sudo apt-get install -y nano
RUN sudo apt-get install -y curl
RUN sudo apt-get install -y php${PHP_VERSION}-xdebug
RUN sudo npm install -g bun

# Install composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN sudo composer self-update

# Install webgrind
# RUN git clone https://github.com/jokkedk/webgrind /var/www/html/wg

# Enable the apache ssl extensions
ENV APACHE_EXTENSION_SOCACHE_SHMCB=1
ENV APACHE_EXTENSION_SSL=1

# Setup the keys
RUN mkdir /home/docker/keys
RUN sudo openssl req -new -newkey rsa:4096 -nodes -keyout /home/docker/keys/server.key -out /home/docker/keys/server.csr -subj "/CN=localhost"
RUN sudo openssl x509 -req -days 365 -in /home/docker/keys/server.csr -signkey /home/docker/keys/server.key -out /home/docker/keys/server.crt
# COPY 000-default-ssl.conf /etc/apache2/sites-enabled/000-default-ssl.conf
