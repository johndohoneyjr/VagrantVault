#!/bin/bash
# abort this script on errors.
set -eux

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y git-core
apt-get install -y unzip
apt-get install -y --no-install-recommends vim

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
