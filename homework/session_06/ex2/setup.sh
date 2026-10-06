#!/bin/bash
set -e

getent group devops-admin >/dev/null 2>&1 || sudo groupadd devops-admin
id deployer >/dev/null 2>&1 || sudo useradd -m -s /bin/bash deployer
sudo usermod -aG devops-admin deployer
echo "deployer:deployer123" | sudo chpasswd
grep -q "%devops-admin ALL=(ALL) NOPASSWD" /etc/sudoers || echo "%devops-admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *" | sudo tee -a /etc/sudoers
sudo visudo -c
