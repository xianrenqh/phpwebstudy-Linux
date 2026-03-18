#!/bin/bash
if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi
password=$1
echo "$password" | sudo -S apt -y install wget
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O /tmp/ACCC4CF8.asc
echo "$password" | sudo -S mv /tmp/ACCC4CF8.asc /usr/share/keyrings/postgresql-keyring.gpg
CODENAME=$(lsb_release -cs)
echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
echo "$password" | sudo -S apt update
