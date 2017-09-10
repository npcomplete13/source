#!/bin/sh

vlan101_ifnames='lan1 lan2 lan3 lan4 lan5 lan6 lan7 lan8 wlan0 wlan1 wlan2 extswitch eth2.101'
vlan102_ifnames='wan eth2.102'
br_ifnames='br-wan br-lan'

# Create VLAN $2 on interface $1
create_vif() {
    ip link add link $1 name $1.$2 type vlan id $2
}

set_bridge_stp_fdd() {
    ip link set dev $1 type bridge stp_state 0
    ip link set dev $1 type bridge forward_delay 0
}

enslave_ifaces() {
    for p in $2
    do
        ip link set $p up
        ip link set $p master $1
        bridge vlan add vid $3 dev $p pvid untagged
    done
}


delete_vids() {
    for p in $2
    do
        bridge vlan del dev $p vid $1 self
        bridge vlan del dev $p vid $1 master
    done
}


echo '#################################'
echo '      Fixing DSA Interfaces'
echo '#################################'

create_vif eth2 101
create_vif eth2 102

set_bridge_stp_fdd br-lan
set_bridge_stp_fdd br-wan

enslave_ifaces br-lan "$vlan101_ifnames" 101

# Make extswitch tagged member of eth2.101
bridge vlan add vid 101 dev extswitch pvid tagged

enslave_ifaces br-wan "$vlan102_ifnames" 102

delete_vids 1 "$vlan101_ifnames $vlan102_ifnames $br_ifnames"

exit 0
