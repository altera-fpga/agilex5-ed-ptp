#!/bin/sh

if [ -z "$DEVKIT" ]; then
        echo -e "Devkit value not set. Please rerun after setting the shell variable <DEVKIT> to 1 or 2."
	exit
fi

packetgenerator --device /dev/uio0 --tx-pkt-size 100 --tx-max-pkt-size 100
packetgenerator --device /dev/uio1 --tx-pkt-size 100 --tx-max-pkt-size 100
packetgenerator --device /dev/uio0 --num-idle-cycles 8
packetgenerator --device /dev/uio1 --num-idle-cycles 8

while [ 1 ]
do
	packetgenerator --device /dev/uio0 --traffic 0
	ip link set eth1 down
	sleep 5
	ip link set eth1 up
	sleep 2
	packetgenerator --device /dev/uio0 --traffic 1
	sleep 3
	if [ "$DEVKIT" == 1 ]; then
		ip addr add 192.168.121.1 dev eth1
		ip route add 192.168.121.0/24 dev eth1 src 192.168.121.1
		ping -I eth1 192.168.121.2 -i 0.0001 -c 400000 -q &
	elif [ "$DEVKIT" == 2 ]; then
		ip addr add 192.168.121.2 dev eth1
		ip route add 192.168.121.0/24 dev eth1 src 192.168.121.2
		ping -I eth1 192.168.121.1 -i 0.0001 -c 400000 -q &
	fi

	packetgenerator --device /dev/uio1 --traffic 0
	ip link set eth2 down
	sleep 5
	ip link set eth2 up
	sleep 3
	packetgenerator --device /dev/uio1 --traffic 1
	sleep 2
	if [ "$DEVKIT" == 1 ]; then
		ip addr add 192.168.122.1 dev eth2
		ip route add 192.168.122.0/24 dev eth2 src 192.168.122.1
		ping -I eth2 192.168.122.2 -i 0.0001 -c 400000 -q &
	elif [ "$DEVKIT" == 2 ]; then
		ip addr add 192.168.122.2 dev eth2
		ip route add 192.168.122.0/24 dev eth2 src 192.168.122.2
		ping -I eth2 192.168.122.1 -i 0.0001 -c 400000 -q &
	fi
	sleep 5
	sleep 100
	packetgenerator --device /dev/uio0 --dump
	packetgenerator --device /dev/uio1 --dump
done
