#!/bin/bash

if [ "$(. /etc/os-release; echo $NAME)" = "Ubuntu" ]; then
    bash ubuntu_and_debian.sh
fi

if [ "$(. /etc/os-release; echo $NAME)" = "Debian" ]; then
    bash ubuntu_and_debian.sh
fi

if [ -f /etc/fedora-release ]; then
     bash fedora.sh
fi

if [ -f /etc/redhat-release ]; then
     bash redhat.sh
fi

if [ -f /etc/centos-release ]; then
     bash centos.sh
fi

if [ -f /etc/SuSE-release ]; then
     bash suse.sh
fi



