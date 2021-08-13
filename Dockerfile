FROM alpine:3
LABEL Maintainer="Son T. Tran <contact@trants.io>"
LABEL Description="Lightweight container with Nginx 1.18 & PHP 8.0 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk --no-cache add \
  curl \
  nginx \
  php8 \
  php8-ctype \
  php8-curl \
  php8-dom \
  php8-fpm \
  php8-gd \
  php8-intl \
  php8-json \
  php8-mbstring \
  php8-mysqli \
  php8-opcache \
  php8-openssl \
  php8-pdo \
  php8-pdo_mysql \
  php8-phar \
  php8-session \
  php8-tokenizer \
  php8-xml \
  php8-xmlreader \
  php8-zlib \
  supervisor \
  && rm /etc/nginx/conf.d/default.conf

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php8 /usr/bin/php

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configure nginx
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/php/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY config/php/php.ini /etc/php8/conf.d/custom.ini

# Configure supervisord
COPY config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www
COPY --chown=nobody src/ /var/www/

# Expose the port nginx is reachable on
EXPOSE 8080 8443

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping