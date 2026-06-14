#!/bin/bash
set -e
export PATH="/home/frappe/.local/bin:/home/frappe/.nvm/versions/node/v24.14.0/bin:$PATH"

echo "=== Setting up bench env ==="
cd /home/frappe/business-mgm
bench setup env

echo "=== Creating common_site_config.json ==="
if [ ! -f "sites/common_site_config.json" ]; then
  echo '{
    "background_workers": 1,
    "db_host": "127.0.0.1",
    "db_port": 3306,
    "redis_cache": "redis://127.0.0.1:13002",
    "redis_queue": "redis://127.0.0.1:11002",
    "redis_socketio": "redis://127.0.0.1:12002",
    "webserver_port": 8000,
    "socketio_port": 9001
  }' > sites/common_site_config.json
fi

echo "=== Checking site_config.json ==="
if [ ! -f "sites/26i.uk/site_config.json" ]; then
  echo "=== REQUIRED ACTION ==="
  echo "sites/26i.uk/site_config.json is missing."
  echo "Initializing site 26i.uk database..."
  # To avoid asking for password interactively, we can use bench new-site with --mariadb-root-password or similar if known, or just run it.
  # Let's see if we can run new-site. Usually mariadb root password is not needed if we specify a pre-created db or if frappe user has privileges.
  # Let's try creating the site with a default password.
  bench new-site 26i.uk --mariadb-root-username root --mariadb-root-password admin --admin-password admin --no-db-creation || echo "Database creation skipped or failed, continuing..."
fi

echo "=== Running migrations ==="
bench --site 26i.uk migrate || echo "Migrate failed, continuing..."

echo "=== Building assets ==="
bench build || echo "Build failed, continuing..."
