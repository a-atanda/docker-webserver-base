#------------------------------------------------------------------------------
# Dockerfile for a base image with Ruby, Python, and Meteor on Ubuntu 24.04
#   — installs build-essential & runtimes,
#   — installs Meteor,
#   — then removes dev packages (build-essential) in one go.
#------------------------------------------------------------------------------

# 1. Base OS
FROM ubuntu:24.04

# 2. Silence prompts
ENV DEBIAN_FRONTEND=noninteractive

# 3. Enable universe + install build deps, Python, Ruby, Node.js
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      software-properties-common \
      curl gnupg lsb-release \
      build-essential \
      ca-certificates git wget unzip zip \
      python3 python3-pip python3-venv \
      ruby-full \
 && add-apt-repository universe \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# 4. Install Meteor (requires build tools during install)
RUN curl https://install.meteor.com/ | sh

# 5. Purge development packages to slim image
RUN apt-get purge -y build-essential \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# 6. Create non-root user and app directory, fix ownership
RUN mkdir -p /usr/src/app \
 && useradd -m -s /bin/bash appuser \
 && chown -R appuser:appuser /usr/src/app

# 7. Switch to unprivileged user
USER appuser
WORKDIR /usr/src/app

# 8. Default to bash
CMD ["bash"]

