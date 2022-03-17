# Redhat Linux Hardening

# updating patch & dependencies
yum install wget sed git -y
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum update -y
yum install ufw -y

# Install fail2ban
yum install fail2ban -y

# update golang optional
rm -rf /usr/local/go
wget -q -c https://dl.google.com/go/$(curl -s https://golang.org/VERSION?m=text).linux-amd64.tar.gz -O go.tar.gz
tar -C /usr/local -xzf go.tar.gz
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export PATH=/usr/local/go/bin:$PATH" >> /etc/profile
source /etc/profile
rm -f go.tar.gz

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
yum autoremove -y

# reload system
sysctl -p
yum install systemd-timesyncd
systemctl restart systemd-timesyncd
ufw --force disable
systemctl restart sshd
