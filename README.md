# <center>neth0</center>
### This script helps you to manage your network configurations

# Options
    -a, -ip                 Change the IP address
	-n, -netmask            Change the netmask
	-g, -gw, -gateway       Change the default gateway
    -i, -interface          Change the interface on which change the specifications. Default is your ethernet one
	-d, -dns                Change the dns server
	--no-ip                 Don't modify the ip
	--no-netmask            Don't modify the netmask
	--no-gw, --no-gateway   Don't modify the default gateway
	--no-dns                Don't modify the dns server
	--default-values        Change the ip, netmask, gateway, dns to default values. If no other options are specified:
	                                ip:        192.168.1.160
	                                netmask:   255.255.255.0
	                                gateway:   192.168.1.1
	                                dns:       192.168.1.1
	                                interface: your ethernet one
<br>                                    

# Usage example
#### Change the ip to `175.15.8.12` and subnet `255.255.255.0`
```bash
./setup.sh -ip 175.15.8.12 -netmask 255.255.255.0
```

#### Change the ip to `192.168.5.22` and dns to `192.168.6.200`
```bash
./setup.sh -ip 192.168.5.22 -dns 192.168.6.200
```

#### Change the configuration to default values without modifying the current ip and set the dns to `192.168.1.200`
```bash
./setup.sh --default-values --no-ip -d 192.168.1.200
```
<br>

# Warnings
- All the options have the priority on `--default-values` one
- If using, for example, `-ip` or `-a` and `--no-ip` flags together, the last one has the priority:<br>
```bash
./setup.sh -a <ip> --no-ip # no ip changed
```
```bash
./setup.sh --no-ip -a <ip> # ip changed to <ip>
```