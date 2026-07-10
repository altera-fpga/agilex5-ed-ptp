#!/bin/sh

if [ -z "$DEVKIT" ]; then
	echo -e "Devkit value not set. Please rerun after setting the shell variable <DEVKIT> to 1 or 2."
	exit
fi

if [ "$DEVKIT" == 1 ]; then
	ping -I eth1 192.168.121.2 -i 0.0001 -c 500000 -q &
elif [ "$DEVKIT" == 2 ]; then
	ping -I eth1 192.168.121.1 -i 0.0001 -c 500000 -q &
fi

if [ "$DEVKIT" == 1 ]; then
	ping -I eth2 192.168.122.2 -i 0.0001 -c 500000 -q &
elif [ "$DEVKIT" == 2 ]; then
	ping -I eth2 192.168.122.1 -i 0.0001 -c 500000 -q &
fi
