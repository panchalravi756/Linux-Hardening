# SUSE Linux Hardening

# update dependencies
sudo zypper install wget sed git

# update system
sudo zypper update

# Install fail2ban
sudo zypper install fail2ban

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
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
systemctl reload firewalld

# free disk space
find /var/log -type f -delete
rm -rf /usr/share/man/*

# reload system
sysctl -p
systemctl restart systemd-timesyncd
systemctl disable firewalld
service sshd restart
