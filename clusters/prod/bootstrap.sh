#!/bin/bash
# ------------------------------------------------------------------
# OmniCloud Enterprise Bootstrap (UBUNTU)
# Cluster: prod
# ------------------------------------------------------------------
set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "[Bootstrap] Initializing node provisioning..."

# 1. OS Tuning for Cassandra (Production Best Practices)
echo "[Bootstrap] Applying Kernel Tuning..."
cat <<EOF > /etc/sysctl.d/99-cassandra.conf
vm.max_map_count = 1048575
vm.swappiness = 1
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 10
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
fs.file-max = 1000000
EOF
sysctl -p /etc/sysctl.d/99-cassandra.conf

# 2. Configure Limits
echo "[Bootstrap] Configuring Limits..."
cat <<EOF > /etc/security/limits.d/cassandra.conf
cassandra - memlock unlimited
cassandra - nofile 100000
cassandra - nproc 32768
cassandra - as unlimited
EOF

# 3. Storage Setup (XFS Formatting & Mounting)
# Detect unformatted NVMe or EBS volumes
echo "[Bootstrap] Configuring Storage..."
DATA_DISK=$(lsblk -dn -o NAME | grep -E "nvme1n1|xvdh|sdb" | head -1)

if [ ! -z "$DATA_DISK" ]; then
    echo "Found data disk: /dev/$DATA_DISK"
    if ! blkid /dev/$DATA_DISK; then
        echo "Formatting /dev/$DATA_DISK with XFS..."
        mkfs.xfs -f -K /dev/$DATA_DISK
    fi
    mkdir -p /var/lib/cassandra
    echo "/dev/$DATA_DISK /var/lib/cassandra xfs defaults,noatime,nofail 0 2" >> /etc/fstab
    mount -a
    chown -R cassandra:cassandra /var/lib/cassandra || true
else
    echo "WARNING: No dedicated data disk found. Using root volume."
fi

# 4. Install Dependencies
echo "[Bootstrap] Installing Software..."
wget https://apt.puppet.com/puppet7-release-focal.deb && dpkg -i $(basename https://apt.puppet.com/puppet7-release-focal.deb) && apt-get update && apt-get install -y git puppet-agent xfsprogs chrony

# 5. GitOps Handshake
echo "[Bootstrap] Cloning Infrastructure Repo..."
mkdir -p /opt/omnicloud
cd /opt/omnicloud
# In prod, you would use a Deploy Token or SSH Key here
git clone https://github.com/Gorak4u/infra-ops.git . 

# 6. Apply Puppet
echo "[Bootstrap] Applying Configuration..."
/opt/puppetlabs/bin/puppet apply /opt/omnicloud/clusters/prod/puppet/manifest.pp

echo "[Bootstrap] Complete. Node Ready."
