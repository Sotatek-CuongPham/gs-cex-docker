# use an existing docker image as a base
FROM php:7.1-fpm

RUN apt-get update -y
RUN apt-get install -y libwebp-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libfreetype6-dev
RUN docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir \
        --with-png-dir --with-zlib-dir --with-xpm-dir --with-freetype-dir \
        --enable-gd-native-ttf

# Download and install a dependency
RUN docker-php-ext-install gd
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install sockets
RUN docker-php-ext-install mbstring
#RUN docker-php-ext-configure zip --with-libzip
RUN docker-php-ext-install zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
RUN composer self-update --1
# Tell the image what to do when it starts

# Node
RUN apt-get install nodejs -y
RUN apt-get install npm -y

# As a container
WORKDIR /home/sites/sotatek-exchange-api

