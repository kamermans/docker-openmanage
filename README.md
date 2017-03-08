# docker-openmanage

Dell OpenManage running in a self-contained Docker container. This container will run on RedHat, CentOS, Debian, Ubuntu, and probably most other Linuxes.

# Compatibility
The host operating system must be Linux, and is known to work in RHEL, CentOS, Debian and Ubuntu.

This image has been tested on the following Dell hardware:

| Hardware            | Status       |
|---------------------|--------------|
| Dell PowerEdge R610 | OK |
| Dell PowerEdge R620 | OK |
| Dell PowerEdge R720 | OK |
| Dell PowerEdge R720xd | OK |
| Dell PowerVault NX3000 | OK |
| Dell Cloud Server C1100 (Direct from Dell) | Not Supported |
| Dell Cloud Server C1100 CS24-TY (OEM Custom Build) | Not Supported |

If you have tested this image on other hardware, please share your results in the form of a GitHub issue or Pull Request, and I'll update the list!

# Firmware Upgrade
To upgrade you Dell's server firmware from Dell Global repository, simply run:

`docker run --rm -ti --privileged --net=host -v /dev:/dev kamermans/docker-openmanage dsu`

You are presented with an interactive text interface where you can select the updates that you would like to apply based on what is available for your Dell server.

> Note: I was able to obtain some of the functionality of this container by reverse-engineering the Dell DSET Live ISO Image.  I have also created a Docker-based version of DSET, which is available in Docker Hub as [kamermans/dell-dset](https://hub.docker.com/r/kamermans/dell-dset/).  This image has only one layer and no Dockerfile as it is a verbatim copy of the OS filesystem from the Dell ISO image.  This image is tagged to match the ISO version, so `kamermans/dell-dset:SLI22_A00` matches the Dell ISO `SLI22_A00`.

# Server Administrator
This is a subtree-split and fork of the OpenManage container that Dell created. Notably, this image includes SNMP support and out-of-the box support for registration in OpenManage Essentials.
Base Project: https://github.com/jose-delarosa/docker-images/tree/master/openmanage81

The easiest way to get up and running is to download the standalone startup script, `openmanage.sh`
from https://raw.githubusercontent.com/kamermans/docker-openmanage/master/openmanage.sh

```
# curl -sSL https://raw.githubusercontent.com/kamermans/docker-openmanage/master/openmanage.sh > ./openmanage.sh
# chmod +x openmanage.sh
# ./openmanage.sh 

OpenManage Server Administrator in a Docker Container

Usage: ./openmanage.sh <start|stop|restart|status|update> [snmp_community] [snmp_trap_dest]
   snmp_community   The SNMP community string to use (default: public)
   snmp_trap_dest   The SNMP trap destination - this is normally the IP
                     or hostname to the OpenManage Essentials server
                     (default: 192.168.0.1)

Note that OpenManage Server Administrator will still work without
 either arguments, but will not be detected by OpenManage Essentials.
```

From here you can start the container (the image will be downloaded from Docker Hub the first time) as well as
 stop, restart and check the status of it.  You can also download or update the image by running `./openmanage update`

To connect it to OpenManage Essentials, you'll need to pass the `snmp_community` and `snmp_trap_dest` arguments
so OpenManage Server Administrator knows how to connect to it.

Note that this container uses the Docker options `--privileged`, `-v /dev:/dev` and `--net=host` in order to access your server 
hardware and correctly report the network configuration.

If you are hesitent to download and run a bash script from some random site on the internet, and you can't understand
my bash code, I would urge you to learn bash, then continue :)

If you choose not to learn bash, here's how to run the container without the init script:

    docker run -d -P \
        --name="openmanage" \
        --privileged \
        --net="host" \
        -v /lib/modules/$(uname -r):/lib/modules/$(uname -r):ro \
        -v /dev:/dev \
        -e "SNMP_COMMUNITY=snmp_community" \
        -e "SNMP_TRAP_DEST=snmp_trap_dest" \
        kamermans/docker-openmanage

Please feel free to browse the source code over at the GitHub repo:
https://github.com/kamermans/docker-openmanage

Special thanks to the following people for their contributions:
 - maltris <https://github.com/maltris>
 - Shane StClair <https://github.com/shane-axiom>
 - Martin Taheri <https://github.com/m3hran>
 - Jose De la Rosa <https://github.com/jose-delarosa>

And a big thanks to Dell for sharing the original container with the open source community!
