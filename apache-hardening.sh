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
