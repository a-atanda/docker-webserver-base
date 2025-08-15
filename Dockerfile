# docker-webserver-base (SLIM) – Ubuntu 24.04 + Nginx + Passenger + Ruby + Python + Node (no Meteor CLI)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Base runtime deps only (no build-essential to keep image small)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg2 dirmngr apt-transport-https \
    ruby-full python3 python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Add Phusion Passenger APT repo for Ubuntu 24.04 (noble) and install Nginx + Passenger
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gnupg2 dirmngr apt-transport-https && \
    curl -fsSL https://oss-binaries.phusionpassenger.com/auto-software-signing-gpg-key.txt \
      | gpg --dearmor > /usr/share/keyrings/phusion.gpg && \
    sh -c 'echo deb [signed-by=/usr/share/keyrings/phusion.gpg] https://oss-binaries.phusionpassenger.com/apt/passenger noble main > /etc/apt/sources.list.d/passenger.list' && \
    apt-get update && \
    apt-get install -y --no-install-recommends nginx libnginx-mod-http-passenger && \
    ln -sf /usr/share/nginx/modules-available/mod-http-passenger.load \
           /etc/nginx/modules-enabled/50-mod-http-passenger.conf && \
    if [ ! -f /etc/nginx/conf.d/mod-http-passenger.conf ]; then \
      printf 'passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;\npassenger_ruby /usr/bin/passenger_free_ruby;\n' \
        > /etc/nginx/conf.d/mod-http-passenger.conf; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Node.js LTS (v20) via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    # keep it slim: drop npm caches
    npm cache clean --force && rm -rf /root/.npm && \
    rm -rf /var/lib/apt/lists/*

# Non-root app user & directories
RUN adduser --disabled-password --gecos '' app && \
    mkdir -p /home/app/webapp && chown -R app:app /home/app

# Nginx site config + default index
RUN rm -f /etc/nginx/sites-enabled/default
COPY docker-webserver.conf /etc/nginx/sites-enabled/docker-webserver.conf
COPY index.html /var/www/html/index.html

# Validate config at build time
RUN nginx -t

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
