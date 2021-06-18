FROM php:fpm
LABEL Maintainer="Son T. Tran <contact@trants.io>"
LABEL Description="Lightweight container with Nginx & PHP for Development."

# Install packages and remove default server definition
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
      libicu-dev \
      nginx \
      procps \
      supervisor && \
    docker-php-ext-configure intl && \
    docker-php-ext-install pdo_mysql intl && \
    pecl install redis apcu xdebug && \
    docker-php-ext-enable apcu xdebug redis

# Create a Self-Signed SSL Certificate
RUN mkdir /etc/nginx/ssl && \
    echo -e "\n\n\n\n\n\n\n" | openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj '/C=US/ST=State/L=Town/O=Office/CN=selfsigned' -keyout /etc/nginx/ssl/selfsigned.key -out /etc/nginx/ssl/selfsigned.crt

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Dockerize configuration for nginx
COPY config/nginx/h5bp /etc/nginx/h5bp

# Dockerize configuration for PHP
COPY config/php/conf.d/*.ini /usr/local/etc/php/conf.d/
COPY config/php/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY config/php/php.ini /usr/local/etc/php/php.ini

# Dockerize configuration for supervisor
COPY config/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY config/supervisor/conf.d/*.conf /etc/supervisor/conf.d-available/

# Dockerize configuration entrypoint CMD
COPY config/entrypoint/entrypoint.sh /usr/local/bin/entrypoint

RUN chmod +x /usr/local/bin/entrypoint

# Add application
RUN chown -R www-data:www-data /var/www

VOLUME /var/www

WORKDIR /var/www

EXPOSE 8000 8443

CMD ["/usr/local/bin/entrypoint"]