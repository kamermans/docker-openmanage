#!/bin/sh -e

usage() {
    cat << EOF
OpenManage Server Administrator in a Docker Container

Usage: ./$(basename $0) <start|stop|restart|status|update> [snmp_community] [snmp_trap_dest]
   snmp_community   The SNMP community string to use (default: public)
   snmp_trap_dest   The SNMP trap destination - this is normally the IP
                     or hostname to the OpenManage Essentials server
                     (default: 192.168.0.1)

Note that OpenManage Server Administrator will still work without
 either arguments, but will not be detected by OpenManage Essentials.
EOF
    exit 1
}

start() {
    case "$(status)" in
        Running)
            echo "Error: Container '$CONTAINER_NAME' is already running"
            exit 1
            ;;
        Stopped)
            echo "Removing stopped container"
            docker rm -fv "$CONTAINER_NAME"
            ;;
    esac

    docker run -d \
        --name="$CONTAINER_NAME" \
        --privileged \
        --net="host" \
        -v /lib/modules/$(uname -r):/lib/modules/$(uname -r) \
        -e "SNMP_COMMUNITY=$SNMP_COMMUNITY" \
        -e "SNMP_TRAP_DEST=$SNMP_TRAP_DEST" \
        $DOCKER_IMAGE
}

stop() {
    case "$(status)" in
        Running)
            echo "Stopping container"
            docker stop  "$CONTAINER_NAME"
            echo "Removing stopped container"
            docker rm -fv "$CONTAINER_NAME"
            exit 1
            ;;
        Stopped)
            echo "Removing stopped container"
            docker rm -fv "$CONTAINER_NAME"
            ;;
        *)
            echo "Container is already stopped"
            ;;
    esac
}

status() {
    STATUS=$(docker inspect --format='{{ .State.Running }}' "$CONTAINER_NAME" 2>/dev/null || echo "Nonexistent")
    echo $STATUS | sed -e 's/true/Running/' -e 's/false/Stopped/g'
}

update() {
    echo "Updating openmanage.sh"
    curl -sSL https://raw.githubusercontent.com/kamermans/docker-openmanage/master/openmanage.sh > $0

    echo "Updating Docker image $DOCKER_IMAGE"
    docker pull "$DOCKER_IMAGE"
}

if [ "$#" -eq 0 ] || [ "x$1" = "x-h" ] || [ "x$1" = "x--help" ]; then
    usage
fi

ACTION="$1"
SNMP_COMMUNITY=${2:-"public"}
SNMP_TRAP_DEST=${3:-"192.168.0.1"}
CONTAINER_NAME="openmanage"
DOCKER_IMAGE="kamermans/docker-openmanage"

case "$ACTION" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop && start
        ;;
    status)
        status
        ;;
    update)
        update
        ;;
    *)
        usage
        ;;
esac
