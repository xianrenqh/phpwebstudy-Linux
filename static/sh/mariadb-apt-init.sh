#!/bin/bash
if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi
password=$1
echo "$password" | sudo -S apt -y install wget
wget -q https://downloads.mariadb.com/MariaDB/mariadb_repo_signing_key.pgp -O /tmp/mariadb_repo_signing_key.pgp
echo "$password" | sudo -S mv /tmp/mariadb_repo_signing_key.pgp /usr/share/keyrings/mariadb-archive-keyring.gpg
CODENAME=$(lsb_release -cs)
echo "deb [signed-by=/usr/share/keyrings/mariadb-archive-keyring.gpg] https://downloads.mariadb.com/MariaDB/repo/10.11/debian $CODENAME main" | sudo tee /etc/apt/sources.list.d/mariadb.list
echo "$password" | sudo -S apt update
