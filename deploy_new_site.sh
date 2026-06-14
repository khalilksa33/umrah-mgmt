#!/bin/bash
export PATH="/home/frappe/.local/bin:/home/frappe/.nvm/versions/node/v24.14.0/bin:$PATH"
cd /home/frappe/business-mgm

echo "=== Installing apps in environment ==="
./env/bin/pip install -e apps/business_management -e apps/insight_nexus

echo "=== Creating site 26i.uk ==="
# We will attempt to create the site. Since mariadb root password is often empty or configured in my.cnf, we try without mariadb password first.
bench new-site 26i.uk --admin-password admin --db-name _business_mgmt --db-host 127.0.0.1 --no-db-creation || bench new-site 26i.uk --admin-password admin --db-name _business_mgmt --db-host 127.0.0.1 --mariadb-root-password admin || bench new-site 26i.uk --admin-password admin --db-name _business_mgmt --db-host 127.0.0.1
