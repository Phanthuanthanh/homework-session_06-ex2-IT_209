#!/bin/bash
set -e

id deployer
groups deployer
sudo -u deployer sudo -l
sudo -u deployer sudo systemctl restart cron
sudo -u deployer sudo systemctl status cron --no-pager
