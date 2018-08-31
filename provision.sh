#!/bin/bash
# abort this script on errors.
set -eux

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y git-core
apt-get install -y unzip
apt-get install -y jq
apt-get install -y --no-install-recommends vim

# Add GPG Key

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repository to APT sources

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce

# Install Docker with latest Policy
sudo apt-get install -y docker-ce

sudo systemctl status docker

# set system configuration.
rm -f /{root,home/*}/.{profile,bashrc}
cp -v -r /vagrant/config/etc/* /etc

su vagrant -c bash <<'VAGRANT_EOF'
#!/bin/bash
# abort this script on errors.
set -eux

# configure git.
git config --global user.name 'John Dohoney'
git config --global user.email 'john.dohoney@gmail.com'
git config --global push.default simple
VAGRANT_EOF

apt-get autoremove -y --purge
