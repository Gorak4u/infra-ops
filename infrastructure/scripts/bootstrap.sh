#!/bin/bash
# ------------------------------------------------------------------
# OmniCloud Smart Bootstrap
# Handles Git clone vs Local Mount for Infrastructure Ops
# ------------------------------------------------------------------
set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "[Bootstrap] Starting Node Provisioning..."

# 1. Install Basic Deps
if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y git curl unzip
    # Install Puppet Agent (Generic)
    wget https://apt.puppet.com/puppet7-release-focal.deb
    dpkg -i puppet7-release-focal.deb
    apt-get update
    apt-get install -y puppet-agent
else
    yum install -y git curl unzip
    rpm -Uvh https://yum.puppet.com/puppet7-release-el-9.noarch.rpm
    yum install -y puppet-agent
fi

# 2. Setup Ops Directory
mkdir -p /opt/infra-ops

# 3. Clone or Link Repo
# If we are in Vagrant (local dev), /vagrant is usually mounted.
if [ -d "/vagrant" ]; then
    echo "[Bootstrap] Detected Vagrant environment. Linking local directory."
    rm -rf /opt/infra-ops
    ln -s /vagrant /opt/infra-ops
else
    echo "[Bootstrap] Detected Cloud environment. Cloning from Git."
    # In PROD: Use a Deploy Key or Token from Secrets Manager
    # For simulation, we assume public or pre-authed
    git clone https://github.com/Gorak4u/infra-ops.git /opt/infra-ops
fi

# 4. Run Puppet Apply
echo "[Bootstrap] Applying Puppet Role..."
# We use the environment.conf logic to set modulepath if r10k ran, but here we force path
/opt/puppetlabs/bin/puppet apply --modulepath=/opt/infra-ops/puppet-control/modules:/opt/infra-ops/puppet-control/site /opt/infra-ops/puppet-control/manifests/site.pp

echo "[Bootstrap] Done."
