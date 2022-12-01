FROM composer:2.4 AS composer

# Set a workdir other than `/`
WORKDIR /app

# Copy src from your repository into a folder called src
COPY src src

# Copy both composer.json and composer.lock
COPY src/composer.* ./

# Run a production-ready composer install
RUN composer install --no-ansi --no-dev --no-interaction --no-scripts --no-progress --optimize-autoloader
###
# Node/NPM Dependencies
###
FROM node:14 as node

# Set a workdir for the new "node" app
WORKDIR /app

# Copy the app folder from the composer image above
COPY --from=composer /app/ /app/

# Copy the build folder from our original repository
#COPY build build

# Copy our package & gulp files
COPY src/package.json ./
COPY src/package-lock.json ./
COPY src/gulpfile.js gulpfile.js

# Run a production-ready, CI focused install
RUN npm ci
# Run a "local" gulp compile (doesn't need global installation)
RUN ./node_modules/.bin/gulp

FROM php:7.4-apache
# Use the debian webroot
WORKDIR /var/www/


COPY --from=composer /app/src/ html
COPY --from=composer /app/vendor/ html
COPY --from=node /app/www html


LABEL org.opencontainers.image.source="https://github.com/blankory/torvi"
EXPOSE 80