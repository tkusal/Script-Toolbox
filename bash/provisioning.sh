#!/bin/bash
USERS=("user1" "user2")
PACKAGES=("nginx" "git" "vim")

# Instalar pacotes
apt update
apt install -y ${PACKAGES[@]}

for USER in "${USERS[@]}"; do
  useradd -m $USER
  echo "$USER:password" | chpasswd
done

echo "Servidor provisionado e usuários criados."