#! /bin/bash

DEFAULT_IP="192.168.1.160"
DEFAULT_NETMASK="255.255.255.0"
DEFAULT_PREFIX="24"
DEFAULT_GW="192.168.1.1"
DEFAULT_DNS="192.168.1.1"

function getIp(){
	cur_ip=$(ip a | grep inet | head -n3 | tail -n1 | cut -d ' ' -f6 | cut -d '/' -f1)
	if [ $cur_ip != "" ]; then
		echo $cur_ip
	else
		echo $DEFAULT_IP	# if no ip is found
	fi
}
function getNetmask(){
	cur_net=$(ip a | grep inet | head -n3 | tail -n1 | cut -d ' ' -f6 | cut -d '/' -f2)
	if [ $cur_net -gt 30 ]; then
		echo $DEFAULT_PREFIX
	elif [ $cur_net != "" ]; then
		echo $cur_net
	else
		echo $DEFAULT_PREFIX	# if no netmask is found
	fi
}

function count(){ # count(string, charToCount)
	char=$2
	str=$1
	
	num=$(echo ${str} | tr -cd ${char} | wc -c)
	echo ${num}
}

function decToBin(){
	echo "obase=2;${1}" | bc
}

function toPrefix(){	# convert x.x.x.x to prefix length
	passed_net=$(count $1 '.')
	if [ $passed_net -gt 0 ]; then
		num=$(echo $1 | cut -d '.' -f1)
		bit1=$(decToBin $num)
		num=$(echo $1 | cut -d '.' -f2)
		bit2=$(decToBin $num)
		num=$(echo $1 | cut -d '.' -f3)
		bit3=$(decToBin $num)
		num=$(echo $1 | cut -d '.' -f4)
		bit4=$(decToBin $num)
		bits=$bit1$bit2$bit3$bit4
		bits=$(echo $bits | tr -cd '1' | wc -c)
		echo $bits
	else
		echo $1
	fi
}


function Help(){

	echo "This script helps you to manage your network configurations"
	echo ""
	echo "USAGE"
	echo "  setup.sh [option] [argument]"
	echo ""
	echo "OPTIONS"
	echo "    -a, -ip                 Change the IP address"
	echo "    -n, -netmask            Change the netmask"
	echo "    -g, -gw, -gateway       Change the default gateway"
	echo "    -i, -interface          Change the interface on which change the specifications. Default is your ethernet one"
	echo "    -d, -dns                Change the dns server"
	echo "    --no-ip                 Don't modify the ip"
	echo "    --no-netmask            Don't modify the netmask"
	echo "    --no-gw, --no-gateway   Don't modify the default gateway"
	echo "    --no-dns                Don't modify the dns server"
	echo "    --default-values        Change the ip, netmask, gateway, dns to default values. If no other options are specified:"
	echo "                                ip:        ${DEFAULT_IP}"
	echo "                                netmask:   ${DEFAULT_NETMASK}"
	echo "                                gateway:   ${DEFAULT_GW}"
	echo "                                dns:       ${DEFAULT_DNS}"
	echo "                                interface: ${interface}"
	echo ""
	echo "WARNINGS"
	echo "    All the options above have the priority on '--default-values' one"
	echo ""
	echo "    If using, for example, '-ip' and '--no-ip' flags together, the last one has the priority:"
	echo "        setup.sh -ip <ip> --no-ip -> no ip changed"
	echo "        setup.sh --no-ip -ip <ip> -> ip changed to <ip>"

}

interface=$(ip -br addr show | head -2 | tail -1 | cut -d ' ' -f1)

# if we can modify those values
DNS=false
GATEWAY=false
IP=false
NETMASK=false
INTERFACE=false

# if --no-[option] is specified. Used to make sure those options have the precedence on --default-values
NOIP_PRESSED=false
NONETMASK_PRESSED=false
NOGW_PRESSED=false
NODNS_PRESSED=false

while [ "$1" != "" ]; do
	case $1 in 
	-a | -ip)
		shift
		ip=$1
		IP=true
		;;
	-n | -netmask)
		shift
		subnet=$1
		NETMASK=true
		;;
	-g | -gw | -gateway)
		shift
		gw=$1
		GATEWAY=true
		;;
	-i | -interface)
		shift
		interface=$1
		INTERFACE=true
		;;
	-d | -dns)
		shift
		dns=$1
		DNS=true
		;;
	--default-values)
		if [ $IP == false ] && [ $NOIP_PRESSED == false ]; then
			ip=${DEFAULT_IP}
			IP=true
		fi
		if [ $NETMASK == false ] && [ $NONETMASK_PRESSED == false ]; then
			subnet=${DEFAULT_NETMASK}
			NETMASK=true
		fi
		if [ $GATEWAY == false ] && [ $NOGW_PRESSED == false ]; then
			gw=${DEFAULT_GW}
			GATEWAY=true
		fi
		if [ $DNS == false ] && [ $NODNS_PRESSED == false ]; then
			dns=${DEFAULT_DNS}
			DNS=true
		fi
		if [ $INTERFACE == false ]; then
			interface=$(ip -br addr show | head -2 | tail -1 | cut -d ' ' -f1)
			INTERFACE=true
		fi
		;;
	--no-dns)
		DNS=false
		NODNS_PRESSED=true
		;;
	--no-ip)
		IP=false
		NOIP_PRESSED=true
		;;
	--no-netmask)
		NETMASK=false
		NONETMASK_PRESSED=true
		;;
	--no-gw | --no-gateway)
		GATEWAY=false
		NOGW_PRESSED=true
		;;
	-h | --help)
		Help
		exit 0
		;;
	*)
		echo "Unrecognized option '${1}'"
		echo "See 'setup.sh --help' for further info"
		exit 1
	esac
	shift
done
# Output results

echo "On interface ${interface}:"

if [ $IP == true ]; then

	def_gw=$(ip route show | grep default | cut -d ' ' -f3)
	temp_gw=$(count $def_gw '.')
	
	old_ip="$(getIp)/$(getNetmask)"
	net=$(getNetmask)
	
# check if this is a valid ip address
	temp=$(count $old_ip '.')	
	if [ $temp -gt 0 ]; then
		sudo ip addr del ${old_ip} dev ${interface}
	fi
	
	sudo ip addr add ${ip}/${net} dev ${interface}

# check if a gateway exists
	if [ $temp_gw -gt 0 ]; then #&& [ $GATEWAY == false ]; then
	
		sudo ip route add ${def_gw} dev ${interface}
		sudo ip route add default via ${def_gw}
	fi
	echo "ip:	 ${ip}"
fi

if [ $NETMASK == true ]; then
	ip=$(getIp)
	old_ip="$(getIp)/$(getNetmask)"
	
	temp=$(count $old_ip '.')
	if [ $temp -gt 0 ]; then
		sudo ip addr del ${old_ip} dev ${interface}
	fi
	
	net=$(toPrefix $subnet)
	sudo ip addr add ${ip}/${net} dev ${interface}

	echo "netmask: ${subnet}"
fi

if [ $GATEWAY == true ]; then
	sudo ip route add ${gw} dev ${interface}
	sudo ip route add default via ${gw}
	echo "gateway: ${gw}"
fi

if [ $DNS == true ]; then
	if [ $(whoami) != "root" ]; then
		echo "You must execute the script as root user in order to set dns address"
	else
		echo "nameserver ${dns}" > /etc/resolv.conf
		echo "dns:	 ${dns}"
	fi
fi

