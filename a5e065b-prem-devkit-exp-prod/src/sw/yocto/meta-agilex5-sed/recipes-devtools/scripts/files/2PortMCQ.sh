#!/bin/sh
echo -e "Programming the Basic IP address..."
echo "4" > /proc/irq/23/smp_affinity && echo "4" > /proc/irq/24/smp_affinity
echo "8" > /proc/irq/25/smp_affinity && echo "8" > /proc/irq/26/smp_affinity
echo "4" > /proc/irq/27/smp_affinity && echo "4" > /proc/irq/28/smp_affinity
echo "8" > /proc/irq/29/smp_affinity && echo "8" > /proc/irq/30/smp_affinity

echo -e "Clearing old PacketSwitch rules Port - 0..."
packetswitch --port 0 --flush-all-keys

FILTERS=$(tc filter show dev eth1 egress 2>/dev/null)
if [[ -z "$FILTERS" ]]; then
	 echo -e "No Filters attached to eth1. Continuing..."
else
	 echo -e "Clearing old TC rules Port - 0..."
	 tc filter del dev eth1 egress
	 tc qdisc del dev eth1 clsact
fi

echo -e "Clearing old PacketSwitch rules Port - 1..."
packetswitch --port 1 --flush-all-keys

FILTERS=$(tc filter show dev eth2 egress 2>/dev/null)
if [[ -z "$FILTERS" ]]; then
	 echo -e "No Filters attached to eth2. Continuing..."
else
	 echo -e "Clearing old TC rules Port - 1..."
	 tc filter del dev eth2 egress
	 tc qdisc del dev eth2 clsact
fi

echo -e "Flushing old IPv4 and IPv6 addresses and routes"
ip addres flush eth1 && ip route flush dev eth1
ip -6 addres flush eth1 && ip -6 route flush dev eth1
ip addres flush eth2 && ip route flush dev eth2
ip -6 addres flush eth2 && ip -6 route flush dev eth2

if [ -z "$1" ]; then
	echo -e "Running script for Devkit $DEVKIT."
else
	if [ "$1" == 1 ] || [ "$1" == 2 ]; then
		echo -e "Setting DEVKIT to $1."
	else
		echo -e "Wrong devkit value. Usage: $0 <1/2>."
		exit
	fi
	export DEVKIT=$1
	echo -e "Running script for Devkit $DEVKIT."
fi

if [ -z "$DEVKIT" ]; then
	echo -e "Devkit value not set. Some confguration may not be set. Please rerun after setting the shell variable <DEVKIT> to 1 or 2."
else
	if [ "$DEVKIT" == 1 ]; then
		ip link set eth1 up && ip addr add 192.168.121.1 dev eth1 && ip route add 192.168.121.0/24 dev eth1 src 192.168.121.1
		ip link set eth2 up && ip addr add 192.168.122.1 dev eth2 && ip route add 192.168.122.0/24 dev eth2 src 192.168.122.1
	elif [ "$DEVKIT" == 2 ]; then
		ip link set eth1 up && ip addr add 192.168.121.2 dev eth1 && ip route add 192.168.121.0/24 dev eth1 src 192.168.121.2
		ip link set eth2 up && ip addr add 192.168.122.2 dev eth2 && ip route add 192.168.122.0/24 dev eth2 src 192.168.122.2
	else
		echo -e "Wrong Devkit value. Please set hell variable <DEVKIT> to 1 or 2."
	fi
fi

ip addr | grep ether

echo -e "Programming the PacketSwitch Port - 0..."
echo -e "Programming the PacketSwitch Generic rule..."
packetswitch --port 0 --set-key --key-index 0 --dest-mac "eth1"  --result 0x1
echo -e "Programming the PacketSwitch - Low priority rules..."
packetswitch --port 0 --set-key --key-index 1 --ethtype 0x0806 --result 0x1
packetswitch --port 0 --set-key --key-index 2 --ethtype 0x0800 --protocol 0x01 --result 0x1
echo -e "Programming the PacketSwitch - IPERF 530X to DMA0..."
packetswitch --port 0 --set-key --key-index 3 --ethtype 0x0800 --dest-port 5301 --result 0x0
packetswitch --port 0 --set-key --key-index 4 --ethtype 0x0800 --dest-port 5302 --result 0x0
packetswitch --port 0 --set-key --key-index 5 --ethtype 0x0800 --src-port 5301 --result 0x0
packetswitch --port 0 --set-key --key-index 6 --ethtype 0x0800 --src-port 5302 --result 0x0
echo -e "Programming the PacketSwitch - IPERF 520X to DMA1..."
packetswitch --port 0 --set-key --key-index 7 --ethtype 0x0800 --dest-port 5201 --result 0x1
packetswitch --port 0 --set-key --key-index 8 --ethtype 0x0800 --dest-port 5202 --result 0x1
packetswitch --port 0 --set-key --key-index 9 --ethtype 0x0800 --src-port 5201 --result 0x1
packetswitch --port 0 --set-key --key-index 10 --ethtype 0x0800 --src-port 5202 --result 0x1
echo -e "Programming the PacketSwitch - PTP Packets to DMA0..."
packetswitch --port 0 --set-key --key-index 11 --dest-mac "01:80:C2:00:00:0E" --result 0x0
packetswitch --port 0 --set-key --key-index 12 --dest-mac "01:1B:19:00:00:00" --result 0x0
packetswitch --port 0 --set-key --key-index 13 --ethtype 0x88F7 --result 0x0
packetswitch --port 0 --set-key --key-index 14 --ethtype 0x88F8 --result 0x0

echo -e "Programming the PacketSwitch Port - 1..."
echo -e "Programming the PacketSwitch Generic rule..."
packetswitch --port 1 --set-key --key-index 0 --dest-mac "eth2"  --result 0x1
echo -e "Programming the PacketSwitch - Low priority rules..."
packetswitch --port 1 --set-key --key-index 1 --ethtype 0x0806 --result 0x1
packetswitch --port 1 --set-key --key-index 2 --ethtype 0x0800 --protocol 0x01 --result 0x1
echo -e "Programming the PacketSwitch - IPERF 530X to DMA0..."
packetswitch --port 1 --set-key --key-index 3 --ethtype 0x0800 --dest-port 5301 --result 0x0
packetswitch --port 1 --set-key --key-index 4 --ethtype 0x0800 --dest-port 5302 --result 0x0
packetswitch --port 1 --set-key --key-index 5 --ethtype 0x0800 --src-port 5301 --result 0x0
packetswitch --port 1 --set-key --key-index 6 --ethtype 0x0800 --src-port 5302 --result 0x0
echo -e "Programming the PacketSwitch - IPERF 520X to DMA1..."
packetswitch --port 1 --set-key --key-index 7 --ethtype 0x0800 --dest-port 5201 --result 0x1
packetswitch --port 1 --set-key --key-index 8 --ethtype 0x0800 --dest-port 5202 --result 0x1
packetswitch --port 1 --set-key --key-index 9 --ethtype 0x0800 --src-port 5201 --result 0x1
packetswitch --port 1 --set-key --key-index 10 --ethtype 0x0800 --src-port 5202 --result 0x1
echo -e "Programming the PacketSwitch - PTP Packets to DMA0..."
packetswitch --port 1 --set-key --key-index 11 --dest-mac "01:80:C2:00:00:0E" --result 0x0
packetswitch --port 1 --set-key --key-index 12 --dest-mac "01:1B:19:00:00:00" --result 0x0
packetswitch --port 1 --set-key --key-index 13 --ethtype 0x88F7 --result 0x0
packetswitch --port 1 --set-key --key-index 14 --ethtype 0x88F8 --result 0x0

if [ -z "$DEVKIT" ]; then
	echo -e "Devkit value not set. Some packetgenerator confguration may not be set. Please rerun after setting the shell variable <DEVKIT> to 1 or 2."
else
	if [ "$DEVKIT" == 1 ]; then
		echo -e "Programming the PacketSwitch - Port 0 User packets to User port..."
		packetgenerator --device /dev/uio0 --dest-mac "12:34:56:78:0A:2" --src-mac "12:34:56:78:0A:1"
		packetswitch --set-key --port 0 --key-index 15 --dest-mac "12:34:56:78:0A:1" --result 0x8
		echo -e "Programming the PacketSwitch - Port 1 User packets to User port..."
		packetgenerator --device /dev/uio1 --dest-mac "12:34:56:78:0A:4" --src-mac "12:34:56:78:0A:3"
		packetswitch --set-key --port 1 --key-index 15 --dest-mac "12:34:56:78:0A:3" --result 0x8
	elif [ "$DEVKIT" == 2 ]; then
		echo -e "Programming the PacketSwitch - Port 0 User packets to User port..."
		packetgenerator --device /dev/uio0 --dest-mac "12:34:56:78:0A:1" --src-mac "12:34:56:78:0A:2"
		packetswitch --set-key --port 0 --key-index 15 --dest-mac "12:34:56:78:0A:2" --result 0x8
		echo -e "Programming the PacketSwitch - Port 1 User packets to User port..."
		packetgenerator --device /dev/uio1 --dest-mac "12:34:56:78:0A:3" --src-mac "12:34:56:78:0A:4"
		packetswitch --set-key --port 1 --key-index 15 --dest-mac "12:34:56:78:0A:4" --result 0x8
	else
		echo -e "Wrong Devkit value. Please set shell variable <DEVKIT> to 1 or 2."
	fi
fi
echo -e "Programming the Packet Generator - Port 0"
packetgenerator --device /dev/uio0 --traffic false --fixed-gap true --pkt-len-mode 0x01 --num-idle-cycles 22 --packet-checker true --num-packets 0xFFFFFFFF --one-shot false --tx-pkt-size 1024 --tx-max-pkt-size 1024
echo -e "Programming the Packet Generator - Port 1"
packetgenerator --device /dev/uio1 --traffic false --fixed-gap true --pkt-len-mode 0x01 --num-idle-cycles 22 --packet-checker true --num-packets 0xFFFFFFFF --one-shot false --tx-pkt-size 1024 --tx-max-pkt-size 1024

echo -e "Programming the IPV6 rules - Port 0"
echo -e "Setting IPv6 local addresses"
if [ -z "$DEVKIT" ]; then
	echo -e "Devkit value not set. Some IPV6 confguration may not be set. Please rerun after setting the shell variable <DEVKIT> to 1 or 2."
else
	if [ "$DEVKIT" == 1 ]; then
		ip -6 addr add 2001:db8:abcd:0012::1/64 dev eth1 && ip link set dev eth1 up
		sleep 2
		ip -6 route add 2001:db8:abcd:0012::1/64 dev eth1 src 2001:db8:abcd:0012::1
	elif [ "$DEVKIT" == 2 ]; then
		ip -6 addr add 2001:db8:abcd:0012::2/64 dev eth1 && ip link set dev eth1 up
		sleep 2
		ip -6 route add 2001:db8:abcd:0012::2/64 dev eth1 src 2001:db8:abcd:0012::2
	else
		echo -e "Wrong Devkit value. Please set shell variable <DEVKIT> to 1 or 2."
	fi
fi

packetswitch --port 0 --set-key --key-index 16 --ethtype 0x86DD --result 0x1
packetswitch --port 0 --set-key --key-index 17 --ethtype 0x86DD --protocol 0x3A  --result 0x1
echo -e "Programming the IPV6 rules - Port 1"
echo -e "Setting IPv6 local addresses"
if [ -z "$DEVKIT" ]; then
	echo -e "Devkit value not set. Some IPV6 confguration may not be set. Please rerun after setting the shell variable <DEVKIT> to 1 or 2."
else
	if [ "$DEVKIT" == 1 ]; then
		ip -6 addr add 2001:db8:abcd:0013::1/64 dev eth2 && ip link set dev eth2 up
		sleep 2
		ip -6 route add 2001:db8:abcd:0013::1/64 dev eth2 src 2001:db8:abcd:0013::1
	elif [ "$DEVKIT" == 2 ]; then
		ip -6 addr add 2001:db8:abcd:0013::2/64 dev eth2 && ip link set dev eth2 up
		sleep 2
		ip -6 route add 2001:db8:abcd:0013::2/64 dev eth2 src 2001:db8:abcd:0013::2

	else
		echo -e "Wrong Devkit value. Please set shell variable <DEVKIT> to 1 or 2."
	fi
fi

packetswitch --port 1 --set-key --key-index 16 --ethtype 0x86DD --result 0x1
packetswitch --port 1 --set-key --key-index 17 --ethtype 0x86DD --protocol 0x3A  --result 0x1


echo -e "Traffic Class Egress QOS programming - Port - eth1"
echo -e "Create QDisc..."
tc qdisc add dev eth1 clsact
echo -e "Create Filters - PTP packets to DMA0..."
MAC1_ADDR="01:80:C2:00:00:0E"
MAC1_HEX=$(echo $MAC1_ADDR | sed 's/://g' | tr 'a-f' 'A-F')
MAC2_ADDR="01:1B:19:00:00:00"
MAC2_HEX=$(echo $MAC2_ADDR | sed 's/://g' | tr 'a-f' 'A-F')
tc filter add dev eth1 egress prio 0 u32 match ip dport 319 0xffff match ip protocol 17 0xff action skbedit priority 0
tc filter add dev eth1 egress prio 0 u32 match ip dport 320 0xffff match ip protocol 17 0xff action skbedit priority 0
tc filter add dev eth1 egress prio 0 u32 match u16 0x${MAC1_HEX:0:4} 0xFFFF at -14 match u32 0x${MAC1_HEX:4:8} 0xFFFFFFFF at -12 action skbedit priority 0
tc filter add dev eth1 egress prio 0 u32 match u16 0x${MAC2_HEX:0:4} 0xFFFF at -14 match u32 0x${MAC2_HEX:4:8} 0xFFFFFFFF at -12 action skbedit priority 0

echo -e "Create Filters - IPERF 530X packets to DMA0..."
tc filter add dev eth1 egress prio 0 u32 match ip dport 5301 0xffff match ip protocol 6 0xff action skbedit priority 0
tc filter add dev eth1 egress prio 0 u32 match ip sport 5301 0xffff match ip protocol 6 0xff action skbedit priority 0
echo -e "Create Filters - IPERF 520X packets to DMA1..."
tc filter add dev eth1 egress prio 0 u32 match ip dport 5201 0xffff match ip protocol 6 0xff action skbedit priority 1
tc filter add dev eth1 egress prio 0 u32 match ip sport 5201 0xffff match ip protocol 6 0xff action skbedit priority 1
echo -e "Create Filters - ICMP packets to DMA1..."
tc filter add dev eth1 egress prio 0 u32 match ip protocol 1 0xff action skbedit priority 1

echo -e "Traffic Class Egress QOS programming - Port - eth2"
echo -e "Create QDisc..."
tc qdisc add dev eth2 clsact
echo -e "Create Filters - PTP packets to DMA0..."
tc filter add dev eth2 egress prio 0 u32 match ip dport 319 0xffff match ip protocol 17 0xff action skbedit priority 0
tc filter add dev eth2 egress prio 0 u32 match ip dport 320 0xffff match ip protocol 17 0xff action skbedit priority 0
tc filter add dev eth2 egress prio 0 u32 match u16 0x${MAC1_HEX:0:4} 0xFFFF at -14 match u32 0x${MAC1_HEX:4:8} 0xFFFFFFFF at -12 action skbedit priority 0
tc filter add dev eth2 egress prio 0 u32 match u16 0x${MAC2_HEX:0:4} 0xFFFF at -14 match u32 0x${MAC2_HEX:4:8} 0xFFFFFFFF at -12 action skbedit priority 0

echo -e "Create Filters - IPERF 530X packets to DMA0..."
tc filter add dev eth2 egress prio 0 u32 match ip dport 5301 0xffff match ip protocol 6 0xff action skbedit priority 0
tc filter add dev eth2 egress prio 0 u32 match ip sport 5301 0xffff match ip protocol 6 0xff action skbedit priority 0
echo -e "Create Filters - IPERF 520X packets to DMA1..."
tc filter add dev eth2 egress prio 0 u32 match ip dport 5201 0xffff match ip protocol 6 0xff action skbedit priority 1
tc filter add dev eth2 egress prio 0 u32 match ip sport 5201 0xffff match ip protocol 6 0xff action skbedit priority 1
echo -e "Create Filters - ICMP packets to DMA2..."
tc filter add dev eth2 egress prio 0 u32 match ip protocol 1 0xff action skbedit priority 1
echo -e "Configuration for Devkit $DEVKIT set"

