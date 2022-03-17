#!/bin/bash

if [ -f /etc/lsb-release ]; then
    bash ubuntu.sh
fi

if [ -f /etc/fedora-release ]; then
     bash fedora.sh
fi

if [ -f /etc/redhat-release ]; then
     bash redhat.sh
fi
