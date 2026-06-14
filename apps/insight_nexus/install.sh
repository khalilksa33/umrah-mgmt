#!/bin/bash

# Insight Nexus Installation Script
# Installs the Frappe module into ERPNext

set -e

BENCH_DIR="/home/frappe/business-mgm"
SITE_NAME="26i.uk"
APP_DIR="$BENCH_DIR/apps/insight_nexus"

echo "==================================="
echo "Installing Insight-Nexus Module"
echo "==================================="

# Check if app directory exists
if [ ! -d "$APP_DIR" ]; then
    echo "Error: App directory not found at $APP_DIR"
    exit 1
fi

# Navigate to bench directory
cd "$BENCH_DIR"

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -e "$APP_DIR"

# Install app on site
echo "Installing app on site: $SITE_NAME"
bench --site "$SITE_NAME" install-app insight_nexus

# Migrate
echo "Running migrations..."
bench --site "$SITE_NAME" migrate

# Build frontend assets
echo "Building frontend assets..."
bench build

echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo "1. Check-in UI: https://26i.uk/app/check-in"
echo "2. Dashboard: https://26i.uk/app/nexus-check-in"
echo ""
echo "API Endpoints (for frontend integration):"
echo "  - Check-in: /api/method/insight_nexus.insight_nexus.api.check_in.check_in"
echo "  - Check-out: /api/method/insight_nexus.insight_nexus.api.check_in.check_out"
echo "  - History: /api/method/insight_nexus.insight_nexus.api.check_in.get_check_ins"
echo "  - Dashboard: /api/method/insight_nexus.insight_nexus.api.check_in.get_dashboard"
