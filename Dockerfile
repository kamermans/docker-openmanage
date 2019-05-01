# Use CentOS 7 base image from Docker Hub
FROM centos:7.6.1810
MAINTAINER Steve Kamerman "https://github.com/kamermans"
#MAINTAINER Jose De la Rosa "https://github.com/jose-delarosa"

# Environment variables
ENV PATH $PATH:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin
ENV TOMCATCFG /opt/dell/srvadmin/lib64/openmanage/apache-tomcat/conf/server.xml
ENV TERM xterm
ENV USER root
ENV PASS password

# Prevent daemon helper scripts from making systemd calls
ENV SYSTEMCTL_SKIP_REDIRECT=1
ENV container docker

# Do overall update and install missing packages needed for OpenManage
RUN mkdir -p /run/lock/subsys \
    && echo "$USER:$PASS" | chpasswd \
    # Add OMSA repo
    && yum -y install \
        gcc wget perl passwd which tar \
        nano dmidecode strace less \
    # Strip systemd so it can run inside Docker
    # Note: "srvadmin-services.sh enable" doesn't work here because systemd is not PID 1 at build-time (it will be when it's run)
    && (cd /usr/lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
    systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /usr/lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /usr/lib/systemd/system/local-fs.target.wants/*; \
    rm -f /usr/lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /usr/lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /usr/lib/systemd/system/basic.target.wants/*; \
    rm -f /usr/lib/systemd/system/anaconda.target.wants/*; \
    wget -q -O - http://linux.dell.com/repo/hardware/dsu/bootstrap.cgi | bash \
    && yum -y install \
        net-snmp \
        srvadmin-all \
        ipmitool \
        dell-system-update \
    && yum clean all \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && for SVC in snmpd instsvcdrv dsm_sa_eventmgrd dsm_sa_datamgrd dsm_sa_snmpd dsm_om_connsvc; do systemctl enable $SVC.service; done \
    # Replace weak Diffie-Hellman ciphers with Elliptic-Curve Diffie-Hellman
    # Symlink in older libstorlibir for sasdupie segfault
    && sed -i \
        -e 's/SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA/TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256/' \
        -e 's/TLS_DHE_RSA_WITH_AES_128_CBC_SHA/TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA/' \
        -e 's/TLS_DHE_DSS_WITH_AES_128_CBC_SHA/TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384/' \
        -e 's/SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA/TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA/' $TOMCATCFG \
    && ln -sf /opt/dell/srvadmin/lib64/libstorelibir-3.so /opt/dell/srvadmin/lib64/libstorelibir.so.5 \
    && echo "dmidecode -t1" >> ~/.bashrc

# Replace systemctl with a partial reimplementation for docker images
# @see: https://github.com/gdraheim/docker-systemctl-replacement
COPY ./resources/systemctl.py /usr/bin/systemctl

# Note: the entrypoint script must contain systemd in the first
# 16 characters of its name so that the Dell srvadmin-services.sh script
# thinks its running with systemd as PID 1 and executes systemd services
COPY ./resources/entrypoint.sh /fake-systemd-entrypoint.sh

COPY resources/snmpd.conf /etc/snmp/snmpd.conf

ENTRYPOINT ["/fake-systemd-entrypoint.sh"]
CMD ["tail", "-f", "/opt/dell/srvadmin/var/log/openmanage/*.xml"]

WORKDIR /opt/dell/srvadmin/bin

EXPOSE 1311 161 162
