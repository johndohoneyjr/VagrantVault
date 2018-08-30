#!/bin/bash
set -eux

sudo su
mkdir -p /opt/vault

# add the vault user.
groupadd --system vault
adduser \
    --system \
    --disabled-login \
    --no-create-home \
    --gecos '' \
    --ingroup vault \
    --home /opt/vault \
    vault
install -d -o root -g vault -m 755 /opt/vault

# Download and install vault v0.11.0.
vault_version=0.11.0
vault_artifact=vault_${vault_version}_linux_amd64.zip
vault_artifact_url=https://releases.hashicorp.com/vault/$vault_version/$vault_artifact
vault_artifact_sha=1681579a5a158a76e37de2854307d649b75ceddd663e71580df25baae036c267
vault_artifact_zip=/tmp/$vault_artifact
wget -q $vault_artifact_url -O$vault_artifact_zip

if [ "$(sha256sum $vault_artifact_zip | awk '{print $1}')" != "$vault_artifact_sha" ]; then
    echo "downloaded $vault_artifact_url failed the checksum verification"
    exit 1
fi

install -d /opt/vault/bin
unzip $vault_artifact_zip -d /opt/vault/bin
ln -s /opt/vault/bin/vault /usr/local/bin
vault -v

# run as a service.
# see https://www.vaultproject.io/guides/production.html
# see https://www.vaultproject.io/docs/internals/security.html
cat >/etc/systemd/system/vault.service <<'EOF'
[Unit]
Description=Vault
After=network.target

[Service]
Type=simple
User=vault
Group=vault
PermissionsStartOnly=true
ExecStart=/opt/vault/bin/vault server -config=/opt/vault/etc/vault.hcl
ExecStartPost=/opt/vault/bin/vault-unseal
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# configure

cat >/home/vagrant/.bash_profile <<EOF
#!/bin/bash

export VAULT_ADDR="http://127.0.0.1:8200"
EOF

cat >/root/.bash_profile <<EOF
#!/bin/bash

export VAULT_ADDR="http://127.0.0.1:8200"
EOF

install -o vault -g vault -m 700 -d /opt/vault/data
install -o root -g vault -m 750 -d /opt/vault/etc
VAULT_HOST='127.0.0.1:8200'
export VAULT_ADDR="http://$VAULT_HOST"
cat >/opt/vault/etc/vault.hcl <<EOF
cluster_name = "HashiCorp"
disable_mlock = true

storage "file" {
    path = "/opt/vault/data"
}

listener "tcp" {
    address     = "$VAULT_HOST"
    tls_disable = 1
}
EOF
install -o root -g root -m 700 /dev/null /opt/vault/bin/vault-unseal
echo '#!/bin/bash' >/opt/vault/bin/vault-unseal

# disable swap.
swapoff --all
sed -i -E 's,^(\s*[^#].+\sswap.+),#\1,g' /etc/fstab

# start vault.
systemctl enable vault
systemctl start vault
sleep 3
journalctl -u vault

# vault operator init -key-shares=1 -key-threshold=1i
# vault-init-result.txt will have something like:
#       Unseal Key 1: sXiqMfCPiRNGvo+tEoHVGy+FHFW092H7vfOY0wPrzpYh
#       Initial Root Token: d2bb2175-2264-d18b-e8d8-18b1d8b61278
#
#       Vault does not store the master key. Without at least 3 keys,
#       your vault will remain permanently sealed.
pushd ~
install -o root -g root -m 600 /dev/null vault-init-result.txt
install -o root -g root -m 600 /dev/null /opt/vault/etc/vault-unseal-keys.txt
install -o root -g root -m 600 /dev/null .vault-token

vault operator init -key-shares=1 -key-threshold=1 > vault-init-result.txt

awk '/Unseal Key [0-9]+: /{print $4}' vault-init-result.txt | head -3 >/opt/vault/etc/vault-unseal-keys.txt
awk '/Initial Root Token: /{print $4}' vault-init-result.txt >.vault-token
popd
cat >/opt/vault/bin/vault-unseal <<EOF
#!/bin/bash
set -eu
sleep 3 # to give vault some time to initialize before we hit its api.
KEYS=\$(cat /opt/vault/etc/vault-unseal-keys.txt)
for key in \$KEYS; do
    /opt/vault/bin/vault unseal -address=$VAULT_ADDR \$key
done
EOF
/opt/vault/bin/vault-unseal

# restart vault to verify that the automatic unseal is working.
systemctl restart vault
sleep 3
journalctl -u vault
vault status

#
# Test Installation
# write an example secret, read it back and delete it.
# see https://www.vaultproject.io/docs/commands/read-write.html
echo "Test of Vault installation"
echo -n abracadabra | vault write secret/example password=- other_key=value
vault read secret/example                   # read all the fields.
vault read -field=password secret/example   # read just the password field.
vault delete secret/example
vault read secret/example || true
