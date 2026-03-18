#!/bin/bash
if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi
password=$1
echo "$password" | sudo -S apt -y install wget
wget -q https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 -O /tmp/RPM-GPG-KEY-mysql-2023
echo "$password" | sudo -S mv /tmp/RPM-GPG-KEY-mysql-2023 /usr/share/keyrings/mysql-2023.gpg
echo "deb [signed-by=/usr/share/keyrings/mysql-2023.gpg] http://repo.mysql.com/apt/debian/ $(lsb_release -cs) mysql-8.0" | sudo tee /etc/apt/sources.list.d/mysql.list
echo "$password" | sudo -S apt update
