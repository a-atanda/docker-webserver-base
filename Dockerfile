# Base image: Use latest Ubuntu LTS (e.g., 24.04 "Noble Numbat")
FROM ubuntu:24.04

# Metadata (optional but recommended)
LABEL maintainer="a-atanda aatanda99@gmail.com"
LABEL description="Base Docker image (Ubuntu) with Nginx + Passenger, Ruby, Python, and Meteor/Node.js"

# Step 1: Update package list and install essential packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg2 apt-transport-https dirmngr \
    build-essential git \
    ruby-full python3 python3-pip \
    nginx libnginx-mod-http-passenger

# Step 2: Install Node.js (latest LTS) via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs

# Step 3: Install Meteor (latest) via npm
RUN npm install -g meteor --unsafe-perm

# Step 4: Add a non-root user for running apps
RUN adduser --disabled-password --gecos '' app \
 && mkdir -p /home/app/webapp && chown -R app:app /home/app

# Step 5: Configure Nginx/Passenger
# Remove default site and add our custom Nginx config
RUN rm -f /etc/nginx/sites-enabled/default
COPY docker-webserver.conf /etc/nginx/sites-enabled/docker-webserver.conf

# Copy a default static index page
COPY index.html /var/www/html/index.html

# Expose port 80 and set the default command to start Nginx in the foreground
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
