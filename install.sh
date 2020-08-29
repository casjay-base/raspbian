#!/usr/bin/env bash

PATH="/usr/bin:/usr/sbin:/usr/local/bin:/bin:/sbin:/usr/games:$HOME/.local/bin"

###############################################################################################

# Path fix
clear
echo ""
echo ""
# Define colors
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[32m'
NC='\033[0m'
###
# Welcome message

wait_time=10 # seconds
temp_cnt=${wait_time}
printf "${GREEN}            *** ${RED}•${GREEN} Welcome to my raspbian Installer ${RED}•${GREEN} ***${NC}\n"
while [[ ${temp_cnt} -gt 0 ]]; do
  printf "\r  ${GREEN}*** ${RED}•${GREEN} You have %2d second(s) remaining to hit Ctrl+C to cancel ${RED}•${GREEN} ***" ${temp_cnt}
  sleep 1
  ((temp_cnt--))
done
printf "${NC}\n\n"

###############################################################################################

#Setup Debian Package Manager
export DEBIAN_FRONTEND=noninteractive

# $APT $APTOPTS $APTINST

APT="DEBIAN_FRONTEND=noninteractive apt-get"
APTOPTS="-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold""
APTINST="--ignore-missing -yy -qq --allow-unauthenticated --assume-yes"

###############################################################################################
if [ ! -f $(which ntpd) ]; then
  sudo $APT $APTOPTS $APTINST install ntp ntpdate </dev/null >/dev/null 2>&1
  sudo systemctl stop ntp >/dev/null 2>&1
  sudo ntpdate ntp.casjay.in >/dev/null 2>&1
  sudo systemctl enable --now ntp >/dev/null 2>&1
fi

###############################################################################################

sudo update-locale LANG=en_US.UTF-8 en_GB.UTF-8 || sudo localectl set-locale LANG=en_US.UTF-8
sudo update-locale

###############################################################################################
#update only
if [ "$update" == "yes" ]; then

  printf "${GREEN} *** ${RED}•${GREEN} Running the updater, this may take a few minutes ${RED}•${GREEN} ***${NC}\n"
  #    IFISONLINE=$( timeout 0.2 ping -c1 8.8.8.8 &>/dev/null ; echo $? )
  CURRIP4="$(/sbin/ifconfig | grep -E "venet|inet" | grep -v "127.0.0." | grep 'inet' | grep -v inet6 | awk '{print $2}' | sed 's#addr:##g' | head -n1)"
  #if [ "$IFISONLINE" -ne "0" ]; then
  #exit 1
  #else

  # Default Web Assets
  sudo bash -c "$(curl -LSs https://github.com/casjay-templates/default-web-assets/raw/master/setup.sh >/dev/null 2>&1)"

  # Ensure version directory exists
  mkdir /etc/casjaysdev/updates/versions >/dev/null 2>&1

  # Update system Files
  sudo git clone -q https://github.com/casjay-base/raspbian /tmp/raspbian >/dev/null 2>&1
  sudo find /tmp/raspbian -type f -exec sed -i "s#MYHOSTIP#$CURRIP4#g" {} \; >/dev/null 2>&1
  sudo find /tmp/raspbian -type f -exec sed -i "s#MYHOSTNAME#$(hostname -s)#g" {} \; >/dev/null 2>&1
  sudo chmod -Rf 755 /tmp/raspbian/usr/local/bin/*
  sudo rm -Rf /tmp/raspbian/etc/{apache2,nginx,postfix,samba} >/dev/null 2>&1
  sudo cp -Rf /tmp/raspbian/{usr,etc,var}* / >/dev/null 2>&1
  sudo cp -Rf /tmp/raspbian/version.txt /etc/casjaysdev/updates/versions/configs.txt >/dev/null 2>&1
  sudo cp -Rf /tmp/raspbian/version.txt /etc/casjaysdev/updates/versions/raspbian.txt >/dev/null 2>&1
  sudo rm -Rf /etc/cron.*/0* >/dev/null 2>&1
  sudo rm -Rf /tmp/raspbian >/dev/null 2>&1

  # Make motd
  sudo cp -Rf /etc/casjaysdev/messages/legal.txt /etc/issue
  if [ -f /usr/games/fortune ] && [ -f /usr/games/cowsay ]; then
    /usr/games/fortune | /usr/games/cowsay | sudo tee >/etc/motd 2>/dev/null
    echo -e "\n\n" | sudo tee >>/etc/motd 2>/dev/null
  fi

  # Update the scripts
  sudo bash -c "$(curl -LSs https://github.com/dfmgr/installer/raw/master/install.sh)" >/dev/null 2>&1 && \
  sudo dotfiles admin installer  >/dev/null 2>&1

  # Done
  NEWVERSION="$(echo $(curl -LSs https://github.com/casjay-base/raspbian/raw/master/version.txt | grep -v "#" | head -n 1))"
  RESULT=$?
  #if [ $RESULT -eq 0 ]; then
  printf "${GREEN}      *** 😃 Updating of raspbian complete 😃 *** ${NC}\n"
  printf "${GREEN}  *** 😃 You now have version number: $NEWVERSION 😃 *** ${NC}\n\n"

  #fi

###############################################################################################
else
  # Installation

  # Install needed packages
  printf "\n  ${GREEN}*** ${RED}•${BLUE} installing needed packages ${RED}•${GREEN} ***${NC}\n"
  sudo $APT $APTOPTS $APTINST install apt-utils dirmngr git curl wget apt-transport-https debian-archive-keyring debian-keyring bzip2 unattended-upgrades </dev/null >/dev/null 2>&1

  # Add Debian keys
  printf "\n  ${GREEN}*** ${RED}•${BLUE} installing apt keys ${RED}•${GREEN} ***${NC}\n"
  curl -Ls https://ftp-master.debian.org/keys/archive-key-8.asc | sudo apt-key add - >/dev/null 2>&1
  curl -Ls https://ftp-master.debian.org/keys/archive-key-8-security.asc | sudo apt-key add - >/dev/null 2>&1
  curl -Ls https://ftp-master.debian.org/keys/archive-key-9.asc | sudo apt-key add - >/dev/null 2>&1
  curl -Ls https://ftp-master.debian.org/keys/archive-key-9-security.asc | sudo apt-key add - >/dev/null 2>&1
  curl -Ls https://ftp-master.debian.org/keys/archive-key-10.asc | sudo apt-key add - >/dev/null 2>&1
  curl -Ls https://ftp-master.debian.org/keys/archive-key-10-security.asc | sudo apt-key add - >/dev/null 2>&1
  curl -Ls https://archive.raspbian.org/raspbian.public.key | sudo apt-key add - >/dev/null 2>&1
  sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2C0D3C0F >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST update >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST update >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST update >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST install vim debian-archive-keyring debian-keyring </dev/null >/dev/null 2>&1

  # Clone repo
  printf "\n  ${GREEN}*** ${RED}•${GREEN} cloning the repository ${RED}•${GREEN} ***${NC}\n"
  sudo rm -Rf /tmp/raspbian >/dev/null 2>&1
  git clone -q https://github.com/casjay-base/raspbian /tmp/raspbian >/dev/null 2>&1

  # Copy apt sources
  printf "\n  ${GREEN}*** ${RED}•${BLUE} copy apt sources ${RED}•${GREEN} ***${NC}\n"
  sudo cp -Rf /tmp/raspbian/etc/apt/* /etc/apt/ >/dev/null 2>&1

  # Install additional packages
  printf "\n  ${GREEN}*** ${RED}•${BLUE} installing additional packages ${RED}•${GREEN} ***${NC}\n"
  sudo $APT $APTOPTS $APTINST update >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST update >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST update >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST install dnsutils net-tools uptimed downtimed mailutils postfix apache2 nginx ntp gnupg cron openssh-server cowsay fortune-mod figlet geany fonts-hack-ttf fonts-hack-otf fonts-hack-web </dev/null >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST install samba tmux neofetch vim-nox fish zsh libapache2-mod-fcgid libapache2-mod-geoip libapache2-mod-php </dev/null >/dev/null 2>&1
  sudo $APT $APTOPTS $APTINST install php7.3 php7.3-bcmath php7.3-bz2 php7.3-cgi php7.3-cli php7.3-common php7.3-curl php7.3-dba php7.3-dev php7.3-enchant php7.3-fpm php7.3-gd php7.3-gmp php7.3-imap php7.3-interbase php7.3-intl php7.3-json php7.3-ldap php7.3-mbstring php7.3-mysql php7.3-odbc php7.3-opcache php7.3-pgsql php7.3-phpdbg php7.3-pspell php7.3-readline php7.3-recode php7.3-snmp php7.3-soap php7.3-sqlite3 php7.3-sybase php7.3-tidy php7.3-xml php7.3-xmlrpc php7.3-xsl php7.3-zip >/dev/null 2>&1
  # Remove anacron stuff
  sudo rm -Rf /etc/cron.*/0*

  # stop nginx httpd
  sudo systemctl stop nginx apache2 >/dev/null 2>&1

  #Set ip and hostname
  CURRIP4="$(/sbin/ifconfig | grep -E "venet|inet" | grep -v "127.0.0." | grep 'inet' | grep -v inet6 | awk '{print $2}' | sed 's#addr:##g' | head -n1)"
  sudo find /tmp/raspbian -type f -exec sed -i "s#MYHOSTIP#$CURRIP4#g" {} \; >/dev/null 2>&1
  sudo find /tmp/raspbian -type f -exec sed -i "s#MYHOSTNAME#$(hostname -s)#g" {} \; >/dev/null 2>&1

  # Ensure version directory exists
  sudo mkdir -p /etc/casjaysdev/updates/versions >/dev/null 2>&1

  # Copy configurations to system
  printf "\n  ${GREEN}*** ${RED}•${BLUE} copying system files ${RED}•${GREEN} ***${NC}\n"
  sudo chmod -Rf 755 /tmp/raspbian/usr/local/bin/*.sh >/dev/null 2>&1
  sudo cp -Rf /tmp/raspbian/{usr,etc,var}* / >/dev/null 2>&1
  sudo cp -Rf /tmp/raspbian/version.txt /etc/casjaysdev/updates/versions/configs.txt >/dev/null 2>&1
  sudo cp -Rf /tmp/raspbian/version.txt /etc/casjaysdev/updates/versions/raspbian.txt >/dev/null 2>&1

  # Cleanup
  sudo rm -Rf /tmp/raspbian >/dev/null 2>&1
  sudo rm -Rf /var/www/html/index*.html >/dev/null 2>&1

  # Setup postfix
  sudo newaliases >/dev/null 2>&1
  sudo systemctl enable --now postfix >/dev/null 2>&1

  # Setup apache2
  sudo bash -c "$(curl -LSs https://github.com/casjay-templates/default-web-assets/raw/master/setup.sh >/dev/null 2>&1)"

  sudo a2enmod proxy_fcgi setenvif access_compat fcgid expires userdir asis autoindex brotli cgid cgi charset_lite data deflate dir env geoip headers http2 lbmethod_bybusyness lua proxy proxy_http2 request rewrite session_dbd speling ssl status vhost_alias xml2enc >/dev/null 2>&1
  sudo a2ensite default-ssl.conf >/dev/null 2>&1
  sudo a2enconf php7.3-fpm >/dev/null 2>&1
  sudo mkdir -p /var/www/html/.well-known >/dev/null 2>&1
  sudo chown -Rf www-data:www-data /var/www /usr/share/httpd >/dev/null 2>&1

  # Install My CA cert
  sudo cp -Rf /etc/ssl/CA/CasjaysDev/certs/ca.crt /usr/local/share/ca-certificates/CasjaysDev.crt >/dev/null 2>&1
  sudo update-ca-certificates >/dev/null 2>&1

  # Setup systemd
  printf "\n  ${GREEN}*** ${RED}•${BLUE} setup systemd ${RED}•${GREEN} ***${NC}\n"
  sudo timedatectl set-local-rtc 0 >/dev/null 2>&1
  sudo timedatectl set-ntp 1 >/dev/null 2>&1
  sudo timedatectl status >/dev/null 2>&1
  sudo timedatectl set-timezone America/New_York >/dev/null 2>&1
  sudo systemctl enable --now ssh >/dev/null 2>&1
  sudo systemctl enable --now apache2 nginx >/dev/null 2>&1

  # Add your public key to ssh
  # set GH to your github username
  if [ ! -z $GH ]; then
    printf "${GREEN}\n  *** ${RED}•${PURPLE} Installing $GH.keys into $HOME/.ssh/authorized_keys  ${RED}•${GREEN} ***${NC}\n\n\n"
    mkdir -p ~/.ssh >/dev/null 2>&1
    chmod 700 ~/.ssh >/dev/null 2>&1
    curl -s https://github.com/$GH.keys | grep -v "Not Found" >>~/.ssh/authorized_keys >/dev/null 2>&1
  fi

  # Make motd
  sudo cp -Rf /etc/casjaysdev/messages/legal.txt /etc/issue
  if [ -f /usr/games/fortune ] && [ -f /usr/games/cowsay ]; then
    /usr/games/fortune | /usr/games/cowsay | sudo tee >/etc/motd 2>/dev/null
    echo -e "\n\n" | sudo tee >>/etc/motd 2>/dev/null
  fi

  # Update the scripts
  printf "\n  ${GREEN}*** ${RED}•${BLUE} setup scripts ${RED}•${GREEN} ***${NC}\n"
  sudo bash -c "$(curl -LSs https://github.com/dfmgr/installer/raw/master/install.sh)" >/dev/null 2>&1 && \
  sudo dotfiles admin installer

  # Print installed version
  NEWVERSION="$(echo $(curl -LSs https://github.com/casjay-base/raspbian/raw/master/version.txt | grep -v "#" | head -n 1))"
  RESULT=$?
  #if [ $RESULT -eq 0 ]; then
  printf "${GREEN}      *** 😃 installation of raspbian complete 😃 *** ${NC}\n"
  printf "${GREEN}  *** 😃 You now have version number: $NEWVERSION 😃 *** ${NC}\n\n"
#else
#printf "${RED} *** • installation of dotfiles completed with errors: $RESULT ***${NC}\n\n"
#fi
###############################################################################################
###printf "\n  ${GREEN}*** ${RED}•${BLUE} #### ${RED}•${GREEN} ***${NC}\n"###

fi

#### END
