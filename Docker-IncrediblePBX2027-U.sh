#!/bin/bash
clear
IMGFILE="RP-2023.01.11.15.09-A20.0.1-F16.0-I2027.2U.B.tar.gz"
version="2027-U.2"
ASTVER="20"
ARCH=`uname -p`

exec > >(tee -i /root/incrediblepbx-install-log.txt)
exec 2>&1

# Check for Ubuntu 22.04
test=`grep 22.04 /etc/os-release`
if [[ -z $test ]]; then
  echo "Ubuntu 22.04 is required for installation."
  exit 6
fi

clear
echo "Installing Incredible PBX 2027. Please wait. This installer runs unattended."
echo "Do NOT press any keys while the installation is underway. Be patient!"

# Set environment variables for passwords (using Coolify Magic Variables)
export ASTERISK_DB_PW=$SERVICE_PASSWORD_ASTERISK
export ADMIN_PASS=$SERVICE_PASSWORD_MARIADB_ROOT

# Set the PATH for VM install protection
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Update and install dependencies (excluding MariaDB)
apt-get update
apt-get install -y build-essential openssh-server apache2 bison flex php \
php-curl php-cli php-mysql php-pear php-gd php-mbstring php-intl php-bcmath \
curl sox libncurses5-dev libssl-dev mpg123 libxml2-dev libnewt-dev sqlite3 \
libsqlite3-dev pkg-config automake libtool autoconf git unixodbc-dev uuid \
uuid-dev libasound2-dev libogg-dev libvorbis-dev libicu-dev libcurl4-openssl-dev \
libical-dev libneon27-dev libsrtp2-dev libspandsp-dev sudo subversion libtool-bin \
python2-dev unixodbc cron dirmngr sendmail-bin sendmail debhelper-compat cmake \
libmariadb-dev php-ldap mailutils dnsutils apt-utils dialog linux-headers-$(uname -r)

# Install Node.js
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
apt-get install -y nodejs

# Configure PHP
apt-get install php7.4 -y
apt-get install php7.4-bcmath php7.4-curl php7.4-gd php7.4-intl php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-xml -y
sed -i 's|128M|256M|' /etc/php/7.4/apache2/php.ini
sed -i 's|128M|256M|' /etc/php/7.4/cli/php.ini
a2enmod php7.4
update-alternatives --set php /usr/bin/php7.4
systemctl restart apache2

# Configure ODBC for external MariaDB
cat <<EOF > /etc/odbcinst.ini
[MySQL]
Description = ODBC for MySQL (MariaDB)
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so
FileUsage = 1
EOF

cat <<EOF > /etc/odbc.ini
[MySQL-asteriskcdrdb]
Description = MySQL connection to 'asteriskcdrdb' database
Driver = MySQL
Server = mariadb
Database = asteriskcdrdb
Port = 3306
Option = 3
EOF

# Install Asterisk
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-20.5.0.tar.gz
tar zxvf asterisk-20.5.0.tar.gz
cd asterisk-20.5.0
contrib/scripts/install_prereq install
contrib/scripts/get_mp3_source.sh
./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled
make
make install
make config
make samples
ldconfig

# Set up Asterisk user and permissions
groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk
chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk

# Configure Asterisk to run as the asterisk user
sed -i 's|;runuser|runuser|' /etc/asterisk/asterisk.conf
sed -i 's|;rungroup|rungroup|' /etc/asterisk/asterisk.conf

# Reload configurations
ldconfig
systemctl restart apache2

# Final message
echo "Incredible PBX 2027 (Ubuntu) installation is complete. Please configure your system as needed and refer to https://nerdvittles.com/happy-new-year-its-incredible-pbx-2027-for-ubuntu-22-04/."
