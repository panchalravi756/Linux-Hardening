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
  yum install nginx -y
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
