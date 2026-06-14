# Business Management (business-mgm) - Deployment on Ubuntu 22.04 LTS

## Overview
This document provides a complete deployment guide for `business-mgm` on **Ubuntu 22.04 LTS** running on **Host B (192.168.8.59)**.

## Repository Changes
- ✅ Renamed: `umrah-mgmt` → `business-mgm`
- ✅ GitHub URL: `https://github.com/khalilksa33/business-mgm`
- ✅ Deploy workflow updated to use new repository
- ✅ Internal app names remain: `business_management`, `insight_nexus`

## Pre-Deployment Checklist

### Host B System Requirements
- [ ] OS: Ubuntu 22.04 LTS
- [ ] SSH access to iicc2@192.168.8.59
- [ ] GitHub runner registered as self-hosted on this IP
- [ ] Minimum 8GB RAM
- [ ] Minimum 50GB disk space
- [ ] Internet connectivity for package installation

### Required Software
- [ ] Git (verify: `git --version`)
- [ ] Python 3.10+ (verify: `python3 --version`)
- [ ] MariaDB 10.6+ (verify: `mysql --version`)
- [ ] Redis 6.0+ (verify: `redis-cli --version`)
- [ ] Node.js 20.20.2 (via NVM)
- [ ] npm & yarn

## Installation Steps

### 1. System Package Installation (Host B)
```bash
# Connect to Host B
ssh iicc2@192.168.8.59

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y \
  git \
  curl \
  wget \
  build-essential \
  python3.10 \
  python3.10-venv \
  python3.10-dev \
  libffi-dev \
  libssl-dev \
  libjpeg-dev \
  zlib1g-dev \
  libldap2-dev \
  mariadb-server \
  redis-server \
  supervisor \
  nodejs \
  npm

# Start services
sudo systemctl enable mariadb redis-server
sudo systemctl start mariadb redis-server

# Verify services running
sudo systemctl status mariadb
sudo systemctl status redis-server
```

### 2. Setup NVM & Node.js (iicc2 user)
```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js v20.20.2
nvm install 20.20.2
nvm use 20.20.2
node --version  # Verify v20.20.2

# Install yarn globally
npm install -g yarn
```

### 3. Clone Repository & Run Setup
```bash
# Create directory
mkdir -p /home/iicc2/business-mgm
cd /home/iicc2/business-mgm

# Clone repository
git clone https://github.com/khalilksa33/business-mgm .

# Run setup script (will take 10-15 minutes)
bash setup_server.sh

# This script will:
# - Install yarn dependencies
# - Fetch Frappe apps (builder, erpnext_ksa, telephony)
# - Install custom apps
# - Create MariaDB database
# - Create Frappe site (26i.uk)
# - Build frontend assets
# - Configure supervisor
```

### 4. Post-Setup Verification
```bash
# Verify bench installation
bench --version

# Check site status
cd /home/iicc2/business-mgm
bench --site 26i.uk doctor

# Check supervisor status
sudo supervisorctl status

# Should see all services RUNNING:
# - business-mgm-umrah-web
# - business-mgm-umrah-schedule
# - business-mgm-umrah-short-worker
# - business-mgm-umrah-long-worker
# - business-mgm-redis-cache
# - business-mgm-redis-queue
# - business-mgm-redis-socketio
# - business-mgm-node-socketio
```

### 5. Configure GitHub Actions Self-Hosted Runner
```bash
# On Host B (as iicc2 user)
mkdir -p /home/iicc2/actions-runner
cd /home/iicc2/actions-runner

# Download latest runner
curl -o actions-runner-linux-x64.tar.gz -L https://github.com/actions/runner/releases/download/v2.313.0/actions-runner-linux-x64-2.313.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64.tar.gz

# Configure runner (follow GitHub prompts)
./config.sh --url https://github.com/khalilksa33/business-mgm --token <GITHUB_TOKEN>

# Run runner as service
./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status

# Verify runner is registered in GitHub repo settings
```

## Post-Deployment Configuration

### Cloudflare Tunnel Setup
```bash
# Install cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb

# Create tunnel
cloudflared tunnel create business-mgm

# Configure tunnel config
sudo nano /root/.cloudflared/config.yml
# Add:
# tunnel: business-mgm
# credentials-file: /root/.cloudflared/business-mgm.json
#
# ingress:
#   - hostname: 26i.uk
#     service: http://localhost:8000
#   - service: http_status:404

# Create DNS record in Cloudflare Dashboard pointing to tunnel

# Start tunnel service
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

### Site Configuration
```bash
# Create initial admin user (if needed)
cd /home/iicc2/business-mgm
bench --site 26i.uk set-admin-password admin

# Enable apps
bench --site 26i.uk install-app business_management
bench --site 26i.uk install-app insight_nexus

# Build cache
bench --site 26i.uk clear-cache
bench --site 26i.uk build
```

## CI/CD Workflow Verification

### Test Automated Deployment
```bash
# Push a test commit to main branch
git commit --allow-empty -m "Test CI/CD pipeline"
git push origin main

# Monitor GitHub Actions
# - Go to repo → Actions → Latest workflow run
# - Should show successful deployment within 2-3 minutes

# Verify deployment
cd /home/iicc2/business-mgm
git log -1  # Should show latest commit

# Check services restarted
sudo supervisorctl status

# Tail deployment logs
tail -f /home/iicc2/business-mgm/logs/web.log
```

## Linux 22.04 Specific Considerations

### 1. Python Version
- Ubuntu 22.04 includes Python 3.10 (no separate installation needed)
- Frappe v15+ requires Python 3.10+ ✅

### 2. MariaDB Configuration
- Default socket: `/var/run/mysqld/mysqld.sock`
- Verify: `grep socket /etc/mysql/my.cnf`
- If using TCP: Update `sites/common_site_config.json` with `"db_socket": null`

### 3. Redis Configuration
- Default port: 6379
- Config: `/etc/redis/redis.conf`
- Custom ports in use:
  - Cache: 13002
  - Queue: 11002
  - SocketIO: 12002

### 4. AppArmor Security
```bash
# If service fails due to AppArmor, check logs
sudo tail -f /var/log/syslog | grep apparmor

# May need to add permissions for specific files
# Contact system administrator if needed
```

### 5. Supervisor Integration
- Configuration: `/etc/supervisor/conf.d/business-mgm.conf`
- Main processes managed:
  - Web server (Gunicorn)
  - Schedule worker
  - Job workers (short/long queue)
  - Redis instances
  - Node.js socket.io server

## Daily Operations

### Start/Stop Services
```bash
# Start all services
sudo supervisorctl start all

# Stop all services
sudo supervisorctl stop all

# Restart specific service
sudo supervisorctl restart business-mgm-umrah-web

# View status
sudo supervisorctl status
```

### Database Maintenance
```bash
# Backup database
mysqldump -u _26i_uk -p _26i_uk > /home/iicc2/backups/26i_uk_$(date +%Y%m%d).sql

# Optimize database
bench --site 26i.uk doctor

# Migrate after code changes
bench --site 26i.uk migrate
```

### Performance Monitoring
```bash
# View real-time system usage
htop

# Check Redis memory
redis-cli INFO stats

# Monitor MariaDB
mysqladmin -u _26i_uk -p status
```

## Troubleshooting

### Service Won't Start
```bash
# Check logs
sudo supervisorctl tail business-mgm-umrah-web
sudo supervisorctl tail business-mgm-umrah-web stderr

# Restart supervisor
sudo systemctl restart supervisor

# Re-read config
sudo supervisorctl reread
sudo supervisorctl update
```

### Database Connection Error
```bash
# Check MariaDB status
sudo systemctl status mariadb

# Restart if needed
sudo systemctl restart mariadb

# Check socket
ls -la /var/run/mysqld/mysqld.sock

# Test connection
mysql -u _26i_uk -p
```

### Redis Connection Issues
```bash
# Check Redis is running
sudo systemctl status redis-server

# Test Redis connection
redis-cli ping

# Check Redis ports
sudo netstat -tlnp | grep redis
```

### Deployment Workflow Stuck
```bash
# Check runner status
cd /home/iicc2/actions-runner
./config.sh --help

# Check runner logs
cat _diag/*.log

# Verify network access to GitHub
curl -I https://github.com
```

## Security Considerations

1. **Database Credentials**
   - Store in `/home/iicc2/business-mgm/sites/common_site_config.json`
   - Restrict file permissions: `chmod 600 sites/*/site_config.json`

2. **API Keys**
   - Never commit secrets to repository
   - Use environment variables or secure credential storage

3. **Firewall Rules** (if applicable)
   - Allow SSH: 22 (from trusted IPs only)
   - Allow HTTP/HTTPS: 80, 443 (via Cloudflare Tunnel)
   - Restrict direct access to 8000, 9001

4. **SSL/TLS**
   - Certificates managed by Cloudflare
   - Origin certificate for server ↔ Cloudflare communication

## Useful Commands

```bash
# Quick status check
cd /home/iicc2/business-mgm
bench --site 26i.uk doctor

# Tail all logs
tail -f logs/*.log

# Rebuild frontend only
bench build

# Run Frappe console
bench --site 26i.uk console

# Install new app
bench get-app <app_name> <repo_url>
bench --site 26i.uk install-app <app_name>

# Create new user
bench --site 26i.uk set-user-password <email> <password>
```

## Contact & Support

- **Deployment Issues**: Check logs and run `bench --site 26i.uk doctor`
- **GitHub Runner Issues**: Check `.vsts/_diag/` in runner directory
- **System Issues**: Ubuntu 22.04 documentation at ubuntu.com
- **Frappe Documentation**: docs.frappe.io

## Version Reference

- Frappe Framework: v15.x (as of deployment)
- ERPNext: Latest stable
- Ubuntu: 22.04 LTS
- Python: 3.10
- Node.js: 20.20.2
- MariaDB: 10.6+
- Redis: 6.2+
