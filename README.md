# docker-webserver-base  

[![Docker Pulls](https://img.shields.io/docker/pulls/aatanda/docker-webserver-base?style=flat-square)](https://hub.docker.com/r/aatanda/docker-webserver-base)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

**🚀 Production-ready Docker base image for Ruby, Python, and Meteor/Node web apps**  
🐳 Lightweight Ubuntu 24.04 image with Nginx + Phusion Passenger to serve static content and run Ruby (Rails/Rack), Python (WSGI/Flask/Django), and Node/Meteor applications.

---

- **OS:** Ubuntu 24.04
- **Web server:** Nginx (runs in foreground)
- **App server:** Passenger (Nginx module) – auto-manages Ruby/Rack, Python/WSGI, and Node apps
- **Runtimes:** Ruby 3.2.x, Python 3.12.x (+ pip), Node 20 LTS
- **Default site (static):** `/var/www/html`
- **Non-root app user:** `app`
- **Port mapping used in examples:** **`8085:80`** (host → container)

> Meteor apps are typically **built to a Node bundle** and then run as a Node app. You don’t need the Meteor CLI in the container to run a production Meteor app.

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [How it works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Quick start: build and run](#quick-start-build-and-run)
- [Serve your own static site](#serve-your-own-static-site)
- [Run sample apps (no rebuild)](#run-sample-apps-no-rebuild)
  - [Ruby (Rack)](#ruby-rack)
  - [Python (WSGI)](#python-wsgi)
  - [Node (simple http server)](#node-simple-http-server)
- [Use this as a base for your app image](#use-this-as-a-base-for-your-app-image)
- [Push image to Docker Hub](#push-image-to-docker-hub)
- [Push this repo to GitHub via SSH](#push-this-repo-to-github-via-ssh)
- [Configuration & paths](#configuration--paths)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Repository Structure

```
docker-webserver-base/
├── Dockerfile              # Ubuntu + Nginx + Passenger + Ruby + Python + Node
├── docker-webserver.conf   # Nginx configuration enabling Passenger and static serving
├── index.html              # Default landing page for quick verification
└── README.md               # ← You’re reading it!
```

- **Dockerfile**  
  Builds the image. It:
  - installs Ruby, Python + pip, Node 20 (via NodeSource),
  - installs Nginx and the Passenger module (from Phusion Passenger APT repo),
  - enables Passenger in Nginx and validates config at build time,
  - sets up a non-root `app` user,
  - copies the provided site config and `index.html`.

- **docker-webserver.conf**  
  Nginx virtual host that:
  - listens on port 80,
  - serves static files from `/var/www/html`,
  - enables Passenger and runs app processes as user `app`,
  - falls back to a Passenger-managed app when no static file matches.

- **index.html**  
  A simple “It works!” page to verify the container is serving static content.

---

## How it works

- **Static requests** (e.g., `/index.html`, images, CSS) are served directly from `/var/www/html` by Nginx.
- **Dynamic requests** fall back to Passenger, which auto-detects:
  - Ruby apps (Rack/Rails) via `config.ru` (or Rails public root config),
  - Python apps via `passenger_wsgi.py`,
  - Node apps via `package.json` and an entry file (e.g., `app.js`).
- The container’s **PID 1** is `nginx -g "daemon off;"`, so the container runs as long as Nginx is alive.

---

## Prerequisites

- **Docker** 24+ installed and running

---

## Quick start: build and run

From the repository root:

```bash
# 1) Build the image
docker build -t aatanda/docker-webserver-base:slim .

# 2) Run the container (host 8085 → container 80)
docker run -d -p 8085:80 --name docker-webserver-base aatanda/docker-webserver-base:slim

# 3) Open your browser
# http://localhost:8085  (should show the "It works!" page)
```

Stop & remove the container:

```bash
docker stop docker-webserver-base && docker rm docker-webserver-base
```

---

## Serve your own static site

Mount a local folder into `/var/www/html`:

```bash
mkdir -p ~/my-static-site
echo "<h1>Hello Static</h1>" > ~/my-static-site/index.html

docker run -d -p 8085:80 \
  -v "$HOME/my-static-site:/var/www/html" \
  --name static-demo \
  aatanda/docker-webserver-base:slim
```

Open: **http://localhost:8085**

---

## Run sample apps (no rebuild)

Passenger can auto-run very small “hello world” apps mounted at `/var/www/html`. These examples don’t install dependencies; they just demonstrate detection.

### Ruby (Rack)

```bash
mkdir -p ./examples/ruby
cat > ./examples/ruby/config.ru <<'EOF'
app = proc { |_env| [200, {"Content-Type" => "text/html"}, ["<h1>Hello from Ruby (Rack)</h1>"]] }
run app
EOF

docker run -d -p 8085:80 \
  -v "$PWD/examples/ruby:/var/www/html" \
  --name ruby-demo \
  aatanda/docker-webserver-base:slim
# Open http://localhost:8085
```

### Python (WSGI)

```bash
mkdir -p ./examples/python
cat > ./examples/python/passenger_wsgi.py <<'EOF'
def application(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/html')])
    return [b"<h1>Hello from Python (WSGI)</h1>"]
EOF

docker run -d -p 8085:80 \
  -v "$PWD/examples/python:/var/www/html" \
  --name py-demo \
  aatanda/docker-webserver-base:slim
# Open http://localhost:8085
```

### Node (simple http server)

```bash
mkdir -p ./examples/node
cat > ./examples/node/app.js <<'EOF'
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type':'text/html'});
  res.end('<h1>Hello from Node</h1>');
});
server.listen(process.env.PORT || 3000);
EOF

cat > ./examples/node/package.json <<'EOF'
{
  "name": "node-hello",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" }
}
EOF

docker run -d -p 8085:80 \
  -v "$PWD/examples/node:/var/www/html" \
  --name node-demo \
  aatanda/docker-webserver-base:slim
# Open http://localhost:8085
```

> **Meteor apps**: build to a Node bundle (outside Docker), then run as a Node app under Passenger. You don’t need the Meteor CLI in the image to run a production bundle.

---

## Use this as a base for your app image

Create a `Dockerfile` in your app and build **FROM this base**:

```dockerfile
# Example: Python app image
FROM aatanda/docker-webserver-base:slim

# Copy app code
WORKDIR /home/app/webapp
COPY . /home/app/webapp

# Install dependencies (uncomment what you use)
# RUN pip install --no-cache-dir -r requirements.txt      # Python
# RUN gem install bundler && bundle install --deployment  # Ruby
# RUN npm ci --omit=dev                                   # Node

# Optional: replace default site with an app-specific Nginx site
# COPY myapp.nginx.conf /etc/nginx/sites-enabled/myapp.conf
# RUN rm -f /etc/nginx/sites-enabled/docker-webserver.conf
```

Then:

```bash
docker build -t aatanda/my-app:slim .
docker run -d -p 8085:80 aatanda/my-app:slim
```

---

## Configuration & paths

- **Site config in this repo:** `docker-webserver.conf` → `/etc/nginx/sites-enabled/docker-webserver.conf`
  - `listen 80;`
  - `root /var/www/html;`
  - `passenger_enabled on;`
  - `passenger_user app;`
  - `try_files $uri $uri/ @passenger_app;` (fallback to app if no static file)
- **Passenger module:** enabled by the Dockerfile and configured globally.
- **Logs:** `/var/log/nginx/access.log` and `/var/log/nginx/error.log` (visible via `docker logs <container>`).
- **Validate Nginx config inside a running container:**  
```bash
docker exec -it <container> nginx -t
```

---

## Troubleshooting

- **Port already in use:** change host port, e.g. `-p 8086:80`.
- **Passenger directive “unknown”:** module not enabled or global conf missing—use the provided Dockerfile as-is.
- **Nothing at `http://localhost:8085`:** check `docker ps`, `docker logs <container>`, and `nginx -t` inside the container.
- **Permissions with mounted code:** ensure files are readable for the container; you can `chown -R app:app` inside if needed.
- **Large image push errors (HTTP 400):** re-login (`docker logout && docker login`), set `"maxConcurrentUploads": 1`, avoid VPN/proxy during push.

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
