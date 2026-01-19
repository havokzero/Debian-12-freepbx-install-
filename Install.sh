#!/usr/bin/env bash

set -e
set -o pipefail

### ---------- colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

fail() {
  echo -e "${RED}[FAIL] $1${NC}"
  exit 1
}

ok() {
  echo -e "${GREEN}[OK] $1${NC}"
}

info() {
  echo -e "${BLUE}[*] $1${NC}"
}

warn() {
  echo -e "${YELLOW}[!] $1${NC}"
}

### ---------- sanity checks ----------
[ "$(id -u)" -eq 0 ] || fail "Run as root"
grep -qi debian /etc/os-release || fail "Not Debian"
grep -qi "12" /etc/os-release || fail "Not Debian 12"

info "System checks passed"

### ---------- update ----------
info "Updating system"
apt update && apt -y upgrade

### ---------- base deps ----------
info "Installing base packages"
apt install -y \
  wget curl nano sudo lsb-release ca-certificates gnupg2 \
  build-essential git sox \
  mariadb-server mariadb-client \
  apache2 \
  nodejs npm \
  libxml2-dev libncurses5-dev uuid-dev libssl-dev \
  libsqlite3-dev libjansson-dev libedit-dev libcurl4-openssl-dev \
  subversion unzip

### ---------- PHP 7.4 ----------
info "Installing PHP 7.4"
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
apt update

apt install -y \
  php7.4 php7.4-cli php7.4-common php7.4-mysql php7.4-curl \
  php7.4-mbstring php7.4-gd php7.4-xml php7.4-zip \
  php7.4-bcmath php7.4-gettext php7.4-imap \
  libapache2-mod-php7.4

php -v | grep -q "7.4" || fail "PHP 7.4 not active"

### ---------- apache config ----------
info "Configuring Apache"
a2dismod php8.* >/dev/null 2>&1 || true
a2enmod php7.4 rewrite
rm -f /var/www/html/index.html

sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

systemctl restart apache2
ok "Apache configured"

### ---------- mariadb ----------
info "Configuring MariaDB"
systemctl enable mariadb --now
mysql -u root -e "SELECT 1;" || fail "MariaDB root access failed"

### ---------- asterisk ----------
info "Installing Asterisk 18"
cd /usr/src
wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz
tar xzf asterisk-18-current.tar.gz
cd asterisk-18*

contrib/scripts/install_prereq install
contrib/scripts/get_mp3_source.sh
./configure
make -j$(nproc)
make install
make samples
make config
ldconfig

groupadd -f asterisk
id asterisk >/dev/null 2>&1 || useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk

chown -R asterisk:asterisk /etc/asterisk /var/{lib,log,spool}/asterisk /usr/lib/asterisk

sed -i 's/^;runuser/runuser/' /etc/asterisk/asterisk.conf
sed -i 's/^;rungroup/rungroup/' /etc/asterisk/asterisk.conf

systemctl enable asterisk --now
ok "Asterisk installed"

### ---------- freepbx ----------
info "Installing FreePBX 16"
cd /usr/src
wget -q https://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz
tar xzf freepbx-16.0-latest.tgz
cd freepbx

./start_asterisk start
./install -n --skip-version-check || fail "FreePBX install failed"

chown -R asterisk:asterisk /var/www/html
systemctl restart apache2 asterisk

### ---------- verification ----------
[ -f /var/www/html/admin/config.php ] || fail "Web UI missing"

IP=$(hostname -I | awk '{print $1}')

echo
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN} FreePBX INSTALL COMPLETE${NC}"
echo -e "${GREEN} Access: http://${IP}/admin/config.php${NC}"
echo -e "${GREEN}==============================================${NC}"
