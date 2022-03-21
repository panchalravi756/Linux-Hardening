#!/bin/bash

if [ -f /etc/lsb-release ]; then
    bash ubuntu.sh
fi

elif [ -f /etc/fedora-release ]; then
     bash fedora.sh
fi

elif [ -f /etc/redhat-release ]; then
     bash redhat.sh
fi

elif [ -f /etc/centos-release ]; then
     bash centos.sh
fi

elif [ -f /etc/SuSE-release ] ; then
     bash suse.sh
fi



