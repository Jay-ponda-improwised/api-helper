FROM circleci/php:7.4-cli

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libxml2-dev \
    zip \
    unzip

# Install PHP extensions including PCOV for code coverage
RUN pecl install pcov && \
    docker-php-ext-enable pcov && \
    docker-php-ext-install xml

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy all files (excluding vendor directory due to .dockerignore)
COPY . .

# Install dependencies (update if lock file is out of sync)
RUN composer update --no-scripts --prefer-dist --no-autoloader

# Generate autoload files
RUN composer dump-autoload --optimize

# Create a script to run composer install when container starts
RUN echo '#!/bin/bash\n\
echo "Running startup script..."\n\
git config --global --add safe.directory /app\n\
composer install\n\
echo "Starting container..."\n\
sleep infinity' > /start.sh && chmod +x /start.sh

# Create a wrapper script for running tests with coverage
RUN echo '#!/bin/bash\n\
# Disable Xdebug by default for better performance\n\
export PHP_IDE_CONFIG=\n\
\n\
# Enable Xdebug only when needed for coverage\n\
if [ "$1" = "coverage" ]; then\n\
    echo "Enabling Xdebug for coverage report..."\n\
    php -d xdebug.mode=coverage ./vendor/bin/phpunit --configuration dev.phpunit.xml --coverage-html=coverage\n\
else\n\
    # Run tests without Xdebug for better performance\n\
    echo "Running tests without Xdebug for better performance..."\n\
    php -n -d extension=/usr/local/lib/php/extensions/no-debug-non-zts-20190902/pcov.so ./vendor/bin/phpunit --configuration dev.phpunit.xml\n\
fi' > /usr/local/bin/run-tests.sh && chmod +x /usr/local/bin/run-tests.sh

# Keep container running
CMD ["/start.sh"]