# Ubuntu Linux Hardening
echo "Running Ubuntu and Debian Script"

# update dependencies
apt-get install wget sed git -y
apt install ufw -y

# update system
apt-get update -y

# Install fail2ban
sudo apt-get install fail2ban -y

# update golang optional
rm -rf /usr/local/go
wget -q -c https://dl.google.com/go/$(curl -s https://golang.org/VERSION?m=text).linux-amd64.tar.gz -O go.tar.gz
tar -C /usr/local -xzf go.tar.gz
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export PATH=/usr/local/go/bin:$PATH" >> /etc/profile
source /etc/profile
rm go.tar.gz

# update nameservers
truncate -s0 /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf

# update ntp servers
truncate -s0 /etc/systemd/timesyncd.conf
echo "[Time]" | sudo tee -a /etc/systemd/timesyncd.conf
echo "NTP=time.cloudflare.com" | sudo tee -a /etc/systemd/timesyncd.conf
echo "FallbackNTP=ntp.ubuntu.com" | sudo tee -a /etc/systemd/timesyncd.conf

# update sysctl.conf
wget -q -c https://raw.githubusercontent.com/conduro/ubuntu/main/sysctl.conf -O /etc/sysctl.conf

# update sshd_config
# wget -q -c https://raw.githubusercontent.com/conduro/ubuntu/main/sshd.conf -O /etc/ssh/sshd_config

# configure firewall
ufw disable
echo "y" | sudo ufw reset
ufw logging off
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp

# defaults to port 22
ufw allow 22/tcp

# free disk space
find /var/log -type f -delete
rm -rf /usr/share/man/*
apt-get autoremove -y
apt-get autoclean -y

# reload system
sysctl -p
update-grub2
systemctl restart systemd-timesyncd
ufw --force disable
service ssh restart

#===  VARIABLES  ===============================================================
#   DESCRIPTION: Variables defining paths to files or directories.
#===============================================================================
APACHE_CONF="/etc/apache2/apache2.conf"
APACHE_DIR="/etc/apache2"
APACHE_DIR_LIB="/usr/lib/apache2"
APACHE_DIR_LOG="/var/log/apache2"
APACHE_DIR_SBIN="/usr/sbin/apache2"
APACHE_DIR_SHARE="/usr/share/apache2"
APACHE_ENVVARS="/etc/apache2/envvars"
APACHE_EVASIVE_CONF="/etc/apache2/mods-enabled/evasive.conf"
APACHE_SECURITY_CONF="/etc/apache2/conf-enabled/security.conf"
APACHE_MOD_SECURITY_CONF="/etc/modsecurity/modsecurity.conf"
APACHE_WEB_ROOT="/var/www/html"
APT_LIST="/var/lib/apt/lists"
APT_PERIODIC_CONF="/etc/apt/apt.conf.d/10periodic"
APT_TIMER="/lib/systemd/system/apt-daily.timer"
AUDITD_CONF="/etc/audit/auditd.conf"
AUDITD_LOG="/var/log/audit/audit.log"
AUDITD_RULES="/etc/audit/audit.rules"
AVAHI_DIR="/var/run/avahi-daemon"
BASHRC="/etc/bash.bashrc"
CRON_CRONTAB="/etc/crontab"
CRON_D="/etc/cron.d"
CRON_DAILY="/etc/cron.daily"
CRON_DENY="/etc/cron.deny"
CRON_HOURLY="/etc/cron.hourly"
CRON_MONTHLY="/etc/cron.monthly"
CRON_WEEKLY="/etc/cron.weekly"
CUPS_DIR="/etc/cups"
FSTAB="/etc/fstab"
GROUP="/etc/group"
GROUP_="/etc/group-"
GRUB_CONFIG="/boot/grub/grub.cfg"
GRUB_MENU="/boot/grub/menu.lst"
GSHADOW="/etc/gshadow"
GSHADOW_="/etc/gshadow-"
HLIP_DIR="/usr/share/hplip"
HOSTS_ALLOW="/etc/hosts.allow"
HOSTS_DENY="/etc/hosts.deny"
INIT_RC="/etc/init.d/rc"
ISSUE="/etc/issue"
ISSUE_NET="/etc/issue.net"
LOG_DIRECTORY="/var/log/"
LOGIN_DEFS="/etc/login.defs"
MARIADB_CNF="/etc/mysql/my.cnf"
MODPROBE_CRAMFS="/etc/modprobe.d/cramfs.conf"
MODPROBE_DCCP="/etc/modprobe.d/dccp.conf"
MODPROBE_FREEVXFS="/etc/modprobe.d/freevxfs.conf"
MODPROBE_HFS="/etc/modprobe.d/hfs.conf"
MODPROBE_HFSPLUS="/etc/modprobe.d/hfsplus.conf"
MODPROBE_JFFS2="/etc/modprobe.d/jffs2.conf"
MODPROBE_RDS="/etc/modprobe.d/rds.conf"
MODPROBE_SCTP="/etc/modprobe.d/sctp.conf"
MODPROBE_SQUASHFS="/etc/modprobe.d/squashfs.conf"
MODPROBE_TIPC="/etc/modprobe.d/tipc.conf"
MODPROBE_UDF="/etc/modprobe.d/udf.conf"
MODPROBE_USB="/etc/modprobe.d/usb.conf"
MODPROBE_VFAT="/etc/modprobe.d/vfat.conf"
PASSWD="/etc/passwd"
PASSWD_="/etc/passwd-"
PHP_INI="/etc/php/7.2/cli/php.ini"
PHP_SESSION_DIR="/var/lib/php/session"
PHP_SOAP_CACHE="/var/lib/php/soap_cache"
PROFILE="/etc/profile"
PWQUALITY_CONF="/etc/security/pwquality.conf"
RESOLV_CONF="/etc/resolv.conf"
SECURITY_LIMITS_CONF="/etc/security/limits.conf"
SHADOW="/etc/shadow"
SHADOW_="/etc/shadow-"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_PAM="/etc/pam.d/sshd"
SYSCTL_CONF="/etc/sysctl.conf"
SYSSTAT="/etc/default/sysstat"
USBGURAD_CONF="/etc/usbguard/usbguard-daemon.conf"

#===  FUNCTION  ================================================================
#          NAME: apache_harden
#   DESCRIPTION: Install and harden apache2.
#     PARAMETER: ---
#===============================================================================
function apache_harden {

    print_info "${DECORATION_BOLD_ON}HARDENING APACHE2${DECORATION_BOLD_OFF}"

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 1.3
    print_info "Installing apache web server with necessary module libs."
    apt -y install software-properties-common python-software-properties 
    # Fix issue with non-UTF-8 locales. https://github.com/oerdnj/deb.sury.org/issues/56
    export LC_ALL=C.UTF-8
    add-apt-repository -y ppa:ondrej/apache2
    apt-key update
    fix_apt_list_lock
    apt update
    apt -y install apache2 libapache2-mod-security2 libapache2-mod-evasive
   
    print_info "Stopping the apache web server service."
    systemctl stop apache2

    print_info "Backing up apache web server configuration files."
    backup_file ${APACHE_CONF}
    backup_file ${APACHE_SECURITY_CONF}
    backup_file ${APACHE_ENVVARS}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 3.1
    print_info "Running the apache web server as a non-root user ${DECORATION_DIM_ON}(as user apache)${DECORATION_DIM_OFF}."
    groupadd -r apache
    useradd apache -r -g apache -d /var/www -s /sbin/nologin
    set_parameter "export APACHE_RUN_USER=" "apache" ${APACHE_ENVVARS} ""
    set_parameter "export APACHE_RUN_GROUP=" "apache" ${APACHE_ENVVARS} ""

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 3.3
    print_info "Locking the apache user account."
    passwd -l apache

    print_info "Loading apache web server environment."
    source ${APACHE_ENVVARS}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 2.3
    print_info "Disabling WebDAV modules."
    a2dismod dav
    a2dismod dav_fs

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 2.4
    print_info "Disabling the status module."
    a2dismod status

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 2.5
    print_info "Disabling the autoindex module."
    a2dismod -f autoindex

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 2.6
    print_info "Disabling proxy modules."
    a2dismod proxy
    a2dismod proxy_connect
    a2dismod proxy_ftp
    a2dismod proxy_http
    a2dismod proxy_fcgi
    a2dismod proxy_scgi
    a2dismod proxy_ajp
    a2dismod proxy_balancer
    a2dismod proxy_express
    a2dismod proxy_wstunnel
    a2dismod proxy_fdpass

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 2.7
    print_info "Disabling the user directories module."
    a2dismod userdir

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 2.8
    print_info "Disabling the info module."
    a2dismod info

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 6.6
    print_info "Enabling the security module."
    a2enmod security2

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 7.1
    print_info "Enabling the ssl module."
    a2enmod ssl

    print_info "Enabling the evasive module."
    a2enmod evasive

    print_info "Enabling the headers module."
    a2enmod headers

    print_info "Enabling the include module."
    a2enmod include

    print_info "Enabling the request timeout module."
    a2enmod reqtimeout

    print_info "Enabling the http2 module."
    a2enmod http2

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 3.4  3.5 3.6 3.7 3.8 3.11
    print_info "Configuring permissions to the directory ${DECORATION_DIM_ON}\"${APACHE_DIR}\"${DECORATION_BOLD_OFF}."
    set_permission_recursive "root:root" "og-rwx" ${APACHE_DIR}
    print_info "Configuring permissions to the directory ${DECORATION_DIM_ON}\"${APACHE_DIR_SBIN}\"${DECORATION_BOLD_OFF}."
    set_permission_recursive "root:root" "og-rwx" ${APACHE_DIR_SBIN}
    print_info "Configuring permissions to the directory ${DECORATION_DIM_ON}\"${APACHE_DIR_SHARE}\"${DECORATION_BOLD_OFF}."
    set_permission_recursive "root:root" "og-rwx" ${APACHE_DIR_SHARE}
    print_info "Configuring permissions to the directory ${DECORATION_DIM_ON}\"${APACHE_DIR_LIB}\"${DECORATION_BOLD_OFF}."
    set_permission_recursive "root:root" "og-rwx" ${APACHE_DIR_LIB}
    print_info "Configuring permissions to the directory ${DECORATION_DIM_ON}\"${APACHE_DIR_LOG}\"${DECORATION_BOLD_OFF}."
    set_permission_recursive "root:apache" "og-rwx" ${APACHE_DIR_LOG}
    print_info "Configuring permissions to the lock file ${DECORATION_DIM_ON}\"${APACHE_LOCK_DIR}\"${DECORATION_BOLD_OFF}."
    set_permission "root:root" "og-w" ${APACHE_LOCK_DIR}
    print_info "Configuring permissions to the directory ${DECORATION_DIM_ON}\"${APACHE_WEB_ROOT}\"${DECORATION_BOLD_OFF}."
    set_permission_recursive "apache:apache" "og-wx" ${APACHE_WEB_ROOT}

    print_info "Configuring document root file to the ${DECORATION_DIM_ON}\"${APACHE_WEB_ROOT}\"${DECORATION_BOLD_OFF}."
    set_parameter "DocumentRoot" ${APACHE_WEB_ROOT} ${APACHE_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 8.1
    print_info "Configing the server HTTP response header to product only."
    set_parameter "ServerTokens" "Prod" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 8.4
    print_info "Disabling file ETag."
    set_parameter "FileETag" "None" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 9.1
    print_info "Configuring the amount of time the server will wait for certain events before failing a request to 10 seconds."
    set_parameter "Timeout" "10" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 10.1
    print_info "Configuring the size limit of the HTTP request line that will be accepted from the client to 512 bytes."
    set_parameter "LimitRequestline" "512" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 10.3
    print_info "Configuring the size limits of the HTTP request header allowed from the client to 1024 bytes ${DECORATION_DIM_ON}(1 KB)${DECORATION_BOLD_OFF}."
    set_parameter "LimitRequestFieldsize" "1024" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 10.4
    print_info "Configuring restrictions for the total size of the HTTP request body sent from the client to 102400 bytes ${DECORATION_DIM_ON}(100 KB)${DECORATION_BOLD_OFF}."
    set_parameter "LimitRequestBody" "102400" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 5.9
    print_info "Disabling old HTTP protocol versions."
    set_parameter "Protocols" "h2 http/1.1" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 5.14
    print_info "Configuring restricting browser frame options to sameorigin."
    print_info "Enabling Content Security Policy."
    set_parameter "Header always set X-Frame-Options" "\"sameorigin\"" ${APACHE_SECURITY_CONF}
    set_parameter "Header always set Content-Security-Policy" "\"default-src 'self'; frame-ancestors 'self'\"" ${APACHE_SECURITY_CONF}

    print_info "Configuring send referrer to all origins, but only the URL sans path ${DECORATION_DIM_ON}(e.g. https://example.com/)${DECORATION_BOLD_OFF}."
    set_parameter "Header always set Referrer-Policy" "\"strict-origin\"" ${APACHE_SECURITY_CONF}

    print_info "Configuring prevent browsers from incorrectly detecting non-scripts as scripts."
    set_parameter "Header always set X-Content-Type-Options" "\"nosniff\"" ${APACHE_SECURITY_CONF}

    print_info "Enabling XSS Protection."
    set_parameter "Header always set X-Xss-Protection" "\"1; mode=block\"" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 6.1
    print_info "Configuring the error log."
    set_parameter "LogLevel" "notice core:info" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 7.4 7.5 7.6 7.8 7.9 7.10
    # Settings inspired by "Mozilla SSL Configuration Generator". https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=apache-2.4.39&openssl=1.1.1b&hsts=yes&profile=modern
    print_info "Adding ssl certification template to the file ${DECORATION_BOLD_ON}\"${APACHE_SECURITY_CONF}\"${DECORATION_BOLD_OFF}."
    echo -e "\n<VirtualHost *:80>" >> ${APACHE_SECURITY_CONF}
    echo -e "\t#Redirect permanent / https://site.org/" >> ${APACHE_SECURITY_CONF}
    echo -e "</VirtualHost>\n" >> ${APACHE_SECURITY_CONF}
    echo -e "\n<VirtualHost *:443>" >> ${APACHE_SECURITY_CONF}
    echo -e "\t#SSLEngine on" >> ${APACHE_SECURITY_CONF}
    echo -e "\t#SSLCertificateFile      /path/to/signed_certificate_followed_by_intermediate_certs" >> ${APACHE_SECURITY_CONF}
    echo -e "\t#SSLCertificateKeyFile   /path/to/private/key" >> ${APACHE_SECURITY_CONF}
    echo -e "\n\t# Uncomment the following directive when using client certificate authentication" >> ${APACHE_SECURITY_CONF}
    echo -e "\t#SSLCACertificateFile    /path/to/ca_certs_for_client_authentication" >> ${APACHE_SECURITY_CONF}
    echo -e "\n\t# HSTS (mod_headers is required) (15768000 seconds = 6 months)" >> ${APACHE_SECURITY_CONF}
    echo -e "\t#Header always set Strict-Transport-Security \"max-age=15768000\"" >> ${APACHE_SECURITY_CONF}
    echo -e "</VirtualHost>\n" >> ${APACHE_SECURITY_CONF}
    print_info "Disabling SSL v3.0, TLS v1.0 and TLS v1.1 protocols."
    set_parameter "SSLProtocol" "all -SSLv3 -TLSv1 -TLSv1.1" ${APACHE_SECURITY_CONF}
    print_info "Restricting weak SSL/TLS ciphers."
    set_parameter "SSLCipherSuite" "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256" ${APACHE_SECURITY_CONF}
    print_info "Enabling preference for the server's cipher preference order."
    set_parameter "SSLHonorCipherOrder" "on" ${APACHE_SECURITY_CONF}
    print_info "Disabling compression on the SSL level."
    set_parameter "SSLCompression" "off" ${APACHE_SECURITY_CONF}
    print_info "Disabling the use of TLS session tickets."
    set_parameter "SSLSessionTickets" "off" ${APACHE_SECURITY_CONF}
    print_info "Disabling support for insecure renegotiation."
    set_parameter "SSLInsecureRenegotiation" "off" ${APACHE_SECURITY_CONF}
    print_info "Enabling stapling of OCSP responses in the TLS handshake."
    set_parameter "SSLUseStapling" "on" ${APACHE_SECURITY_CONF}
    print_info "Configuring timeout for OCSP stapling queries to 5 seconds."
    set_parameter "SSLStaplingResponderTimeout" "5" ${APACHE_SECURITY_CONF}
    print_info "Disabling pass stapling related OCSP errors on to client."
    set_parameter "SSLStaplingReturnResponderErrors" "off" ${APACHE_SECURITY_CONF}
    print_info "Configuring expiring responses in the OCSP stapling cache."
    set_parameter "SSLStaplingCache" "\"shmcb:/var/run/ocsp(128000)\"" ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 5.7
    print_info "Configuring HTTP request for the GET, POST and HEAD methods only."
    echo -e "\n<Location />" >> ${APACHE_SECURITY_CONF}
    echo -e "\tOrder allow,deny" >> ${APACHE_SECURITY_CONF}
    echo -e "\tAllow from all" >> ${APACHE_SECURITY_CONF}
    echo -e "\t<LimitExcept GET POST HEAD>" >> ${APACHE_SECURITY_CONF}
    echo -e "\t\tdeny from all" >> ${APACHE_SECURITY_CONF}
    echo -e "\t</LimitExcept>" >> ${APACHE_SECURITY_CONF}
    echo -e "</Location>\n" >> ${APACHE_SECURITY_CONF}

    # CIS Benchmark Apache server 2.4 v1.4.0 chapter 5.8
    print_info "Disabling HTTP TRACE method."
    set_parameter "TraceEnable" "off" ${APACHE_SECURITY_CONF}

    print_info "Enabling OWASP Core Rule Set."
    cp ${APACHE_MOD_SECURITY_CONF}-recommended ${APACHE_MOD_SECURITY_CONF}
    set_parameter "SecRuleEngine" "On" ${APACHE_MOD_SECURITY_CONF}

    systemctl start apache2
}

apache_harden

# Install, Configure and Optimize MySQL
install_secure_mysql(){
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing MySQL"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install mysql-server
    echo ""
    echo -n " configuring MySQL............ "
    cp templates/mysql /etc/mysql/mysqld.cnf; echo " OK"
    mysql_secure_installation
    cp templates/usr.sbin.mysqld /etc/apparmor.d/local/usr.sbin.mysqld
    service mysql restart
}

install_secure_mysql

# Install Nginx
install_nginx(){ 
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing NginX Web Server"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list
  echo "deb-src http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list
  curl -O https://nginx.org/keys/nginx_signing.key && apt-key add ./nginx_signing.key
  apt update
  apt install nginx
  yum update
  yum install nginx
}

##############################################################################################################

#Compile ModSecurity for NginX

compile_modsec_nginx(){
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Install Prerequisites and Compiling ModSecurity for NginX"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
# for ubuntu,debian
apt install bison flex make automake gcc pkg-config libtool doxygen git curl zlib1g-dev libxml2-dev libpcre3-dev build-essential libyajl-dev yajl-tools liblmdb-dev rdmacm-utils libgeoip-dev libcurl4-openssl-dev liblua5.2-dev libfuzzy-dev openssl libssl-dev
# for redhat, centos, fedora
yum install bison flex make automake gcc pkg-config libtool doxygen git curl zlib1g-dev libxml2-dev libpcre3-dev build-essential libyajl-dev yajl-tools liblmdb-dev rdmacm-utils libgeoip-dev libcurl4-openssl-dev liblua5.2-dev libfuzzy-dev openssl libssl-dev

cd /opt/
git clone https://github.com/SpiderLabs/ModSecurity

cd ModSecurity
git checkout v3/master
git submodule init
git submodule update

./build.sh
./configure
make
make install

cd ..

nginx_version=$(dpkg -l |grep nginx | awk '{print $3}' | cut -d '-' -f1)

wget http://nginx.org/download/nginx-$nginx_version.tar.gz
tar xzvf nginx-$nginx_version.tar.gz

git clone https://github.com/SpiderLabs/ModSecurity-nginx

cd nginx-$nginx_version/

./configure --with-compat --add-dynamic-module=/opt/ModSecurity-nginx
make modules

cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

cd /etc/nginx/

mkdir /etc/nginx/modsec
cd /etc/nginx/modsec
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
mv /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf.example /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf

cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf

echo "Include /etc/nginx/modsec/modsecurity.conf" >> /etc/nginx/modsec/main.conf
echo "Include /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf" >> /etc/nginx/modsec/main.conf
echo "Include /etc/nginx/modsec/owasp-modsecurity-crs/rules/*.conf" >> /etc/nginx/modsec/main.conf

wget -P /etc/nginx/modsec/ https://github.com/SpiderLabs/ModSecurity/raw/v3/master/unicode.mapping
cd $jshielder_home

  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Configuring ModSecurity for NginX"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  cp templates/nginx /etc/nginx/nginx.conf
  cp templates/nginx_default /etc/nginx/conf.d/default.conf
  service nginx restart
}

install_nginx
compile_modsec_nginx
