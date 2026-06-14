#!/bin/bash
set -e
export PATH="/home/frappe/.local/bin:/home/frappe/.nvm/versions/node/v24.14.0/bin:$PATH"
cd /home/frappe/business-mgm

echo "=== Symlinking production apps ==="
PROD_APPS_DIR="/home/frappe/frappe/frappe-production/apps"

for app in frappe erpnext hrms crm telephony builder helpdesk drive erpnext_ksa payments ecommerce_integrations; do
  if [ ! -d "apps/$app" ]; then
    echo "Symlinking $app..."
    ln -s "$PROD_APPS_DIR/$app" "apps/$app"
  fi
done

echo "=== Installing all apps in python environment ==="
./env/bin/pip install -e apps/frappe
./env/bin/pip install -e apps/erpnext
./env/bin/pip install -e apps/hrms
./env/bin/pip install -e apps/crm
./env/bin/pip install -e apps/telephony
./env/bin/pip install -e apps/builder
./env/bin/pip install -e apps/helpdesk
./env/bin/pip install -e apps/drive
./env/bin/pip install -e apps/erpnext_ksa
./env/bin/pip install -e apps/payments
./env/bin/pip install -e apps/ecommerce_integrations
./env/bin/pip install -e apps/insight_nexus
./env/bin/pip install -e apps/business_management

echo "=== Setup complete ==="
