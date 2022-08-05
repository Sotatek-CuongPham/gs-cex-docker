# use an existing docker image as a base
FROM php:8.1-fpm

RUN apt-get update -y
RUN apt-get install -y libwebp-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libfreetype6-dev
RUN apt-get install -y --no-install-recommends \
libfreetype6-dev \
libjpeg62-turbo-dev \
libpng-dev

# Download and install a dependency
RUN docker-php-ext-install gd
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install sockets
RUN docker-php-ext-install mbstring
RUN docker-php-ext-configure zip --with-libzip
RUN docker-php-ext-install zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
# Tell the image what to do when it starts

# As a container

# Node
RUN apt-get install nodejs -y
RUN apt-get install npm -y

WORKDIR /home/sites/be

