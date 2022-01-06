#!/bin/bash

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

# Start Dell services
echo "Starting Dell services, this may take a few minutes..."
systemctl start snmpd.service
srvadmin-services.sh start
srvadmin-services.sh status

# Run any passed commands
if [ "$#" -gt 0 ]; then
    # Use eval instead of exec so this script remains PID 1
    eval "$@"
fi
tail -f /opt/dell/srvadmin/var/log/openmanage/*.xml
