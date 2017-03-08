#!/bin/bash -e

# Print system information, serial number, etc
dmidecode -t1

echo "Configuring SNMPD"

if [ "x$SNMP_COMMUNITY" != "x" ]; then
    echo "  Setting community to '$SNMP_COMMUNITY'"
    sed -i -E "s/^(com2sec notConfigUser.*|Trapsink.*) public.*\$/\1 $SNMP_COMMUNITY/g" /etc/snmp/snmpd.conf
fi

if [ "x$SNMP_TRAP_DEST" != "x" ]; then
    # Use the IP or resolve the hostname to an IP
    SNMP_TRAP_DEST=$(grep -P "^\d+\.\d+\.\d+\.\d+$" <<< "$SNMP_TRAP_DEST" || getent hosts "$SNMP_TRAP_DEST" | cut -d" " -f1)
    echo "  Setting trap sink (destination) to '$SNMP_TRAP_DEST'"
    sed -i -E "s/^(Trapsink ).* (.*)\$/\1 $SNMP_TRAP_DEST \2/g" /etc/snmp/snmpd.conf
fi

/etc/init.d/snmpd start
srvadmin-services.sh restart

tail -f /opt/dell/srvadmin/var/log/openmanage/dcsys64.xml
