#!/bin/bash

apt-get update
apt-get -y install wget unzip less emacs
wget https://releases.hashicorp.com/vault/1.4.2/vault_1.4.2_linux_amd64.zip
unzip vault_1.4.2_linux_amd64.zip
install -m 755 vault /usr/local/bin
mkdir -p /etc/vault
project_name=$(gcloud config get-value project)
cat <<EOF > /etc/vault/config.json
disable_cache = true
disable_mlock = true
ui = true
listener "tcp" {
    address = "127.0.0.1:8200"
    tls_disable = 0
    tls_cert_file = "/etc/vault/ssl/vault-test.cert"
    tls_key_file = "/etc/vault/ssl/vault-test.key"
}
seal "gcpckms" {
  project     = "${project_name}"
  region      = "global"
  key_ring    = "auto-unseal-keyring"
  crypto_key  = "auto-unseal-key-ring-key"
}
storage "file" {
  path = "/etc/vault/data"
}
max_lease_ttl = "10h"
default_lease_ttl = "10h"
log_level = "Debug"
EOF

cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=vault service
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/config.json

[Service]
EnvironmentFile=-/etc/sysconfig/vault
Environment=GOMAXPROCS=2
Restart=on-failure
ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.json
StandardOutput=file:/var/log/vault.log
StandardError=file:/var/log/vault_error.log
LimitMEMLOCK=infinity
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/vault/ssl
echo "$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/ssl_cert -H "Metadata-Flavor: Google")" > /etc/vault/ssl/vault-test.cert
echo "$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/ssl_issuer -H "Metadata-Flavor: Google")" >> /etc/vault/ssl/vault-test.cert
echo "$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/ssl_prikey -H "Metadata-Flavor: Google")" > /etc/vault/ssl/vault-test.key

ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

systemctl start vault

vault_hostname=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/vault_hostname -H "Metadata-Flavor: Google")
echo "export VAULT_ADDR='https://${vault_hostname}:8200'" >> /etc/bash.bashrc

zone=$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google")

# 一応消しておく
gcloud compute instances remove-metadata $(hostname) --keys ssl_cert --zone ${zone}
gcloud compute instances remove-metadata $(hostname) --keys ssl_issuer --zone ${zone}
gcloud compute instances remove-metadata $(hostname) --keys ssl_prikey --zone ${zone}

export VAULT_ADDR=https://${vault_hostname}:8200
vault operator init -recovery-shares=1 -recovery-threshold=1 > /etc/vault/init.file 2>/tmp/hoge



