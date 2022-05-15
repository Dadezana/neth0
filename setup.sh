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
function getNetmasks(){
	cur_net=$(ip a | grep inet | head -n3 | tail -n1 | cut -d ' ' -f6 | cut -d '/' -f2)
	if [ $cur_net != "" ]; then
		echo $cur_net
	else
		echo $DEFAULT_PREFIX	# if no netmask is found
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

interface=$(ip a | head -n7 | tail -n -1 | cut -d ':' -f 2 | cut -d ' ' -f 2)

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
			interface=$(ip a | head -n7 | tail -n -1 | cut -d ':' -f 2 | cut -d ' ' -f 2)
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
	sudo ifconfig $interface $ip up
	# sudo ip addr add ${ip}/$(getNetmask) dev ${interface}
	echo "ip:	 ${ip}"
fi

if [ $NETMASK == true ]; then
	sudo ifconfig $interface netmask $subnet up
	# sudo ip addr add $(getIp)/$subnet	#* here convert (for example) 255.255.255.0 to /24
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


