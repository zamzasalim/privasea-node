#!/bin/bash

curl -s https://data.zamzasalim.xyz/file/uploads/asclogo.sh | bash
sleep 5

function success_message {
    echo "[✔] $1"
}

function error_message {
    echo "[✘] $1"
}

# Cek apakah Docker sudah terpasang
if ! command -v docker &> /dev/null
then
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
    success_message "Docker berhasil diinstal dan dijalankan."
else
    success_message "Docker sudah terpasang."
fi

# Tarik gambar Docker
if docker pull privasea/acceleration-node-beta:latest; then
    success_message "Gambar Docker berhasil diunduh"
else
    error_message "Gagal mengunduh gambar Docker"
    exit 1
fi

# Buat direktori konfigurasi
if mkdir -p $HOME/privasea/config; then
    success_message "Direktori konfigurasi berhasil dibuat"
else
    error_message "Gagal membuat direktori konfigurasi"
    exit 1
fi

# Buat file keystore
if docker run -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
    success_message "File keystore berhasil dibuat"
else
    error_message "Gagal membuat file keystore"
    exit 1
fi

# Pindahkan file keystore
if mv $HOME/privasea/config/UTC--* $HOME/privasea/config/wallet_keystore; then
    success_message "File keystore berhasil dipindahkan"
else
    error_message "Gagal memindahkan file keystore"
    exit 1
fi

# Pilihan untuk melanjutkan atau tidak
read -p "Apakah Anda ingin melanjutkan untuk menjalankan node (y/n)? " choice
if [[ "$choice" != "y" ]]; then
    echo "Proses dibatalkan."
    exit 0
fi

# Meminta password untuk keystore
echo "Masukkan password untuk keystore:"
read -s KEystorePassword
echo ""

# Jalankan node
if docker run -d -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD=$KEystorePassword privasea/acceleration-node-beta:latest; then
    success_message "Node berhasil dijalankan"
else
    error_message "Gagal menjalankan node"
    exit 1
fi

echo "Proses selesai."
echo "File konfigurasi di: $HOME/privasea/config"
echo "Keystore: wallet_keystore"
echo "Password Keystore: $KEystorePassword"
