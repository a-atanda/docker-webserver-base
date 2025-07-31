# docker-webserver-base

[![Docker Pulls](https://img.shields.io/docker/pulls/aatanda/webserver-base)](https://hub.docker.com/r/aatanda/webserver-base)  
[![Docker Image Size](https://img.shields.io/docker/image-size/aatanda/webserver-base/latest)](https://hub.docker.com/r/aatanda/webserver-base)  
[![GitHub Release](https://img.shields.io/github/v/release/a-atanda/docker-webserver-base)](https://github.com/a-atanda/docker-webserver-base/releases)

A **minimal** Ubuntu-based Docker image preconfigured with:

- **Python 3.12** + \`pip3\` + \`venv\`  
- **Ruby 3.2** + RubyGems  
- **Node.js 20.x**  
- **Meteor** (latest installer)  
- A default non-root user (\`appuser\`) for safe development  

This image serves as a **base** for building Ruby, Python, or Meteor applications in a consistent containerized environment.

---

## Table of Contents

1. [Features](#features)  
2. [Prerequisites](#prerequisites)  
3. [Getting Started](#getting-started)  
   - [Clone & Build Locally](#clone--build-locally)  
   - [Pull from Docker Hub](#pull-from-docker-hub)  
4. [Running the Container](#running-the-container)  
5. [Using the Image](#using-the-image)  
   - [Python](#python)  
   - [Ruby](#ruby)  
   - [Meteor](#meteor)  
6. [Extending This Base Image](#extending-this-base-image)  
7. [Directory Structure](#directory-structure)  
8. [Contributing](#contributing)  
9. [License](#license)

---

## Features

- **Single image** with three major runtimes (Python, Ruby, Node/Meteor).  
- **Non-root user** (\`appuser\`) ensures files created by your app aren’t owned by root.  
- **No leftover build tools**—\`build-essential\` and compilers are purged after installation to keep it lean.  
- **Up-to-date runtimes** as of Ubuntu 24.04 and Node.js 20.x LTS.  

---

## Prerequisites

- Docker Engine 24.x or newer  
- (Optional) [Docker Compose](https://docs.docker.com/compose/) for multi-service orchestration  

---

## Getting Started

### Clone & Build Locally

```bash
git clone git@github.com:a-atanda/docker-webserver-base.git
cd docker-webserver-base

# Build with your Docker Hub username as the tag
docker build -t aatanda/webserver-base:latest .
```

### Pull from Docker Hub

```bash
docker pull aatanda/webserver-base:latest
```

---

## Running the Container

Start an interactive shell as the non-root \`appuser\`:

```bash
docker run --rm -it aatanda/webserver-base:latest bash
```

You’ll be dropped into \`/home/appuser\`:

```bash
\$ pwd
/home/appuser

\$ python3 --version      # Python 3.12.x
\$ pip3 --version

\$ ruby --version         # Ruby 3.2.x
\$ gem --version

\$ node --version         # v20.x.x
\$ meteor --version       # Meteor x.x.x
```

---

## Using the Image

### Python

```bash
docker run --rm \
  -v "\$PWD":/usr/src/app -w /usr/src/app \
  aatanda/webserver-base:latest \
  python3 your_script.py
```

### Ruby

```bash
docker run --rm \
  -v "\$PWD":/usr/src/app -w /usr/src/app \
  aatanda/webserver-base:latest \
  bash -lc "gem install bundler && bundle install && ruby app.rb"
```

### Meteor

```bash
docker run --rm -p 3000:3000 \
  -v "\$PWD":/usr/src/app -w /usr/src/app \
  aatanda/webserver-base:latest \
  meteor --settings settings.json
```

---

## Extending This Base Image

Use \`FROM\` inheritance to build your application image:

```dockerfile
FROM aatanda/webserver-base:latest

WORKDIR /usr/src/app
COPY . .

# Python example
RUN pip3 install -r requirements.txt
CMD ["python3", "app.py"]
```

Or for a Ruby app:

```dockerfile
FROM aatanda/webserver-base:latest

WORKDIR /usr/src/app
COPY . .

RUN gem install bundler && bundle install
CMD ["ruby", "app.rb"]
```

---

## Directory Structure

```text
.
├── Dockerfile
├── README.md          # ← You’re reading it!
└── .dockerignore
```

---

## Contributing

1. Fork the repo  
2. Create a feature branch:
   ```bash
   git checkout -b feat/your-feature
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add your feature"
   ```
4. Push to your branch:
   ```bash
   git push origin feat/your-feature
   ```
5. Open a Pull Request on GitHub

Please ensure your changes include:

- Clear updates to \`README.md\`  
- Dockerfile modifications that maintain a small final image  
- Testing instructions if you add new functionality  

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
