# Use CentOS 7 base image from Docker Hub
FROM centos:centos7
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

RUN mkdir -p /run/lock/subsys

# Do overall update and install missing packages needed for OpenManage
RUN yum -y update && \
    yum -y install gcc wget perl passwd which tar libstdc++.so.6 compat-libstdc++-33.i686 glibc.i686 \
        net-snmp net-snmp-sysvinit nano

COPY resources/snmpd.conf /etc/snmp/snmpd.conf
RUN /etc/init.d/snmpd start

# Set login credentials
RUN echo "$USER:$PASS" | chpasswd

# Add OMSA repo
RUN wget -q -O - http://linux.dell.com/repo/hardware/latest/bootstrap.cgi | bash

# Let's "install all", however we can select specific components instead
RUN yum -y install srvadmin-all && yum clean all

# Replace weak Diffie-Hellman ciphers with Elliptic-Curve Diffie-Hellman
RUN sed -i -e 's/SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA/TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256/' -e 's/TLS_DHE_RSA_WITH_AES_128_CBC_SHA/TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA/' -e 's/TLS_DHE_DSS_WITH_AES_128_CBC_SHA/TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384/' -e 's/SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA/TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA/' $TOMCATCFG

COPY resources/init.sh /init.sh

WORKDIR /opt/dell/srvadmin/bin
CMD ["/init.sh"]

EXPOSE 1311 161 162
