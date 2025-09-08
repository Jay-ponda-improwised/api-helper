FROM php:7.4-cli

# Install system dependencies
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

# Keep container running
CMD ["/start.sh"]