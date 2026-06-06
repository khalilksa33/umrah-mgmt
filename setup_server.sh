#!/bin/bash
# Umrah Management Bench Setup Script
# Run this script on the erp-worker-02 server under the iicc2 user.

set -e

echo "=== Starting Umrah Management Bench Setup Script ==="

# 1. Global yarn installation
echo "Checking and installing yarn..."
npm install -g yarn || sudo npm install -g yarn

# 2. Setup environment variables & paths
export PATH="/home/iicc2/.nvm/versions/node/v20.20.2/bin:/home/iicc2/.local/bin:$PATH"
cd /home/iicc2/umrah-mgmt

# 3. Ensure logs and config/pids directory exists
mkdir -p logs config/pids

# 4. Install socketio dependencies inside frappe app
echo "Installing socketio dependencies..."
if [ -d "apps/frappe" ]; then
    cd apps/frappe
    yarn install
    cd ../..
else
    echo "Warning: apps/frappe not found!"
fi

# 5. Fetch builder app (branch version-15 or develop fallback)
echo "Fetching builder app..."
if [ ! -d "apps/builder" ]; then
    bench get-app --branch version-15 builder https://github.com/frappe/builder || bench get-app --branch develop builder https://github.com/frappe/builder
fi

# 6. Fetch erpnext_ksa app
echo "Fetching erpnext_ksa app..."
if [ ! -d "apps/erpnext_ksa" ]; then
    bench get-app erpnext_ksa https://github.com/frappe/erpnext_ksa
fi

# 7. Fetch telephony app
echo "Fetching telephony app..."
if [ ! -d "apps/telephony" ]; then
    bench get-app telephony https://github.com/frappe/telephony
fi

# 8. Install custom apps into virtual environment
echo "Installing custom apps (insight_nexus, umrah_management) to python env..."
./env/bin/pip install -e apps/insight_nexus
./env/bin/pip install -e apps/umrah_management

# 9. Ensure MariaDB is running
echo "Checking MariaDB service status..."
if systemctl is-active --quiet mariadb; then
    echo "MariaDB is running."
else
    echo "MariaDB is not running. Attempting to start..."
    sudo systemctl start mariadb
fi

# 10. Create the site if it doesn't exist
if [ ! -f "sites/26i.uk/site_config.json" ]; then
    echo "Creating new site 26i.uk (You will be prompted for MariaDB root and Admin password)..."
    bench new-site 26i.uk
else
    echo "Site 26i.uk already exists."
fi

# 11. Install all apps on 26i.uk site
echo "Installing apps on 26i.uk..."
bench --site 26i.uk install-app \
  erpnext \
  ecommerce_integrations \
  payments \
  helpdesk \
  builder \
  crm \
  hrms \
  drive \
  erpnext_ksa \
  telephony \
  insight_nexus \
  umrah_management

# 12. Build assets
echo "Building bench assets..."
bench build

# 13. Link supervisor and restart services
echo "Configuring supervisor..."
sudo ln -sf /home/iicc2/umrah-mgmt/config/supervisor.conf /etc/supervisor/conf.d/umrah-mgmt.conf
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart all
sudo supervisorctl status

echo "=== Setup Completed Successfully ==="
