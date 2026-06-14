#!/bin/bash
export PATH="/home/frappe/.local/bin:/home/frappe/.nvm/versions/node/v24.14.0/bin:$PATH"
cd /home/frappe/business-mgm

echo "=== Re-initializing site 26i.uk with --force ==="
# We will use bench new-site. We will try with a guess of mariadb root password (admin, root, or blank)
bench new-site 26i.uk --admin-password admin --db-name _business_mgmt --db-host 127.0.0.1 --mariadb-root-password admin --force || bench new-site 26i.uk --admin-password admin --db-name _business_mgmt --db-host 127.0.0.1 --mariadb-root-password root --force || bench new-site 26i.uk --admin-password admin --db-name _business_mgmt --db-host 127.0.0.1 --force
