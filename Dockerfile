FROM resin/rpi-raspbian:latest
MAINTAINER Bruno Cardoso Cantisano <bruno.cantisano@gmail.com>

LABEL Centreon container for Raspberry Pi

#Centreon-Clib
RUN apt-get clean \
    && apt-get update \
    && apt-get install -y cmake build-essential wget \
    && cd /tmp \
    && wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-clib/centreon-clib-1.4.2.tar.gz \
    && tar xzf centreon-clib-1.4.2.tar.gz \
    && cd /tmp/centreon-clib-1.4.2/build/ \
    && cmake -DWITH_TESTING=0 -DWITH_PREFIX=/usr -DWITH_SHARED_LIB=1 -DWITH_STATIC_LIB=0 -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig . \
    && make \
    && make install \
    && rm -rf /tmp/centreon-clib-1.4.2 \
    && rm -f /tmp/centreon-clib-1.4.2.tar.gz

#Centreon-Connector
RUN apt-get install -y libperl-dev \
    && cd /tmp \
    && wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-connectors/centreon-connector-1.1.2.tar.gz \
    && tar xzf centreon-connector-1.1.2.tar.gz \
    && cd /tmp/centreon-connector-1.1.2/perl/build/ \
    && cmake -DWITH_PREFIX=/usr -DWITH_PREFIX_BINARY=/usr/lib/centreon-connector -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include -DWITH_TESTING=0 . \
    && make \
    && make install \
    && rm -f /tmp/centreon-connector-1.1.2.tar.gz

#Centreon SSH Connector
RUN apt-get install -y libssh2-1-dev libgcrypt11-dev \
    && cd /tmp/centreon-connector-1.1.2/ssh/build/ \
    && cmake -DWITH_PREFIX=/usr -DWITH_PREFIX_BINARY=/usr/lib/centreon-connector -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include -DWITH_TESTING=0 . \
    && make \
    && make install \
    && rm -rf /tmp/centreon-connector-1.1.2 

#Centreon-Engine
RUN groupadd -g 6001 centreon-engine \
    && useradd -u 6001 -g centreon-engine -m -r -d /var/lib/centreon-engine -c "Centreon-engine Admin" -s /bin/bash centreon-engine \
    && apt-get install -y libcgsi-gsoap-dev libssl-dev libxerces-c-dev \
    && cd /tmp \
    && wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-engine/centreon-engine-1.4.15.tar.gz \
    && tar xzf centreon-engine-1.4.15.tar.gz \
    && cd /tmp/centreon-engine-1.4.15/build/ \
    && cmake -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include -DWITH_CENTREON_CLIB_LIBRARY_DIR=/usr/lib -DWITH_PREFIX=/usr -DWITH_PREFIX_BIN=/usr/sbin -DWITH_PREFIX_CONF=/etc/centreon-engine \
    -DWITH_USER=centreon-engine -DWITH_GROUP=centreon-engine -DWITH_LOGROTATE_SCRIPT=1 -DWITH_VAR_DIR=/var/log/centreon-engine -DWITH_RW_DIR=/var/lib/centreon-engine/rw -DWITH_STARTUP_DIR=/etc/init.d  \
    -DWITH_PKGCONFIG_SCRIPT=1 -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig -DWITH_TESTING=0 -DWITH_WEBSERVICE=1 . \
    && make \
    && make install \
    && update-rc.d centengine defaults \
    && rm -rf /tmp/centreon-engine-1.4.15 \
    && rm -f /tmp/centreon-engine-1.4.15.tar.gz

#Plugins
RUN apt-get install -y nagios-plugins-basic \
    && chown root:centreon-engine /usr/lib/nagios/plugins/check_icmp \
    && chmod u+s /usr/lib/nagios/plugins/check_icmp

#Centreon-Broker
RUN groupadd -g 6002 centreon-broker \
    && useradd -u 6002 -g centreon-broker -m -r -d /var/lib/centreon-broker -c "Centreon-broker Admin"  -s /bin/bash centreon-broker \
    && apt-get install -y librrd-dev libqt4-dev libqt4-sql-mysql libgnutls28-dev lsb-release \
    && cd /tmp \
    && wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-broker/centreon-broker-2.10.1.tar.gz \
    && tar xzf centreon-broker-2.10.1.tar.gz \
    && cd /tmp/centreon-broker-2.10.1/build/ \
    && cmake -DWITH_DAEMONS='central-broker;central-rrd' -DWITH_GROUP=centreon-broker -DWITH_PREFIX=/usr -DWITH_PREFIX_BIN=/usr/sbin -DWITH_PREFIX_CONF=/etc/centreon-broker -DWITH_PREFIX_LIB=/usr/lib/centreon-broker \
    -DWITH_PREFIX_MODULES=/usr/share/centreon/lib/centreon-broker -DWITH_STARTUP_DIR=/etc/init.d -DWITH_STARTUP_SCRIPT=auto -DWITH_TESTING=0 -DWITH_USER=centreon-broker . \
    && make \
    && make install \
    && update-rc.d cbd defaults \
    && rm -rf /tmp/centreon-broker-2.10.1 \
    && rm -f /tmp/centreon-broker-2.10.1.tar.gz

#SNMP
RUN apt-get install -y snmp snmpd libnet-snmp-perl libsnmp-perl snmptrapd \
    && sed -i 's|agentAddress udp:127.0.0.1:161|agentAddress udp:localhost:161|g' /etc/snmp/snmpd.conf \
    && sed -i 's|#rocommunity public|rocommunity public|g' /etc/snmp/snmpd.conf \
    && sed -i 's|#agentAddress udp:161|agentAddress udp:161|g'  /etc/snmp/snmpd.conf \
    && sed -i "s|SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -g snmp -I -smux,mteTrigger,mteTriggerConf -p /run/snmpd.pid'|SNMPDOPTS='-LS4d -Lf /dev/null -u snmp -g snmp -I -smux -p /var/run/snmpd.pid'|g" /etc/default/snmpd \
    && sed -i 's|TRAPDRUN=no|TRAPDRUN=yes|g' /etc/default/snmptrapd \
    && sed -i "s|TRAPDOPTS='-Lsd -p /run/snmptrapd.pid'|TRAPDOPTS='-On -Lsd -p /var/run/snmptrapd.pid'|g" /etc/default/snmptrapd

#mibs
RUN wget -P /tmp http://archive.ubuntu.com/ubuntu/pool/multiverse/s/snmp-mibs-downloader/snmp-mibs-downloader_1.1.tar.gz \
    && cd /tmp \
    && tar xvzf snmp-mibs-downloader_1.1.tar.gz \
    && rm -f /tmp/snmp-mibs-downloader_1.1.tar.gz \

COPY files/Makefile /tmp/snmp-mibs-downloader-1.1
COPY files/start.sh /start.sh
COPY files/foreground.sh /etc/apache2/foreground.sh
COPY files/supervisord.conf /etc/supervisord.conf
COPY files/centreon-silent-install.txt /centreon-silent-install.txt
COPY files/centreon  /etc/sudoers.d/

RUN apt-get install smistrip \
    && cd /tmp/snmp-mibs-downloader-1.1 \
    && make install \
    && download-mibs \
    && ln -s /usr/share/mibs/ /usr/share/snmp/mibs

ENV MIBDIRS=/usr/share/snmp/mibs
ENV MIBS=ALL

#comentando linha
RUN sed -i 's|mibs ALL|#mibs ALL|g' /etc/snmp/snmp.conf \
    && service snmpd restart \
    && service snmptrapd restart \
    && snmpwalk -c public -v 2c localhost \
    && groupadd -g 6000 centreon \
    && useradd -u 6000 -g centreon -m -r -d /var/lib/centreon -c "Centreon Admin" -s /bin/bash centreon \
    && usermod -aG centreon-engine centreon \
    && usermod -aG centreon-broker centreon \
    && usermod -aG centreon centreon-engine \
    && usermod -aG centreon centreon-broker \
    && echo -e "centreon\ncentreon" | passwd centreon \
    && apt-get install -y sudo apache2 librrds-perl libconfig-inifiles-perl libnet-snmp-perl libdigest-hmac-perl libcrypt-des-ede3-perl libdbd-sqlite3-perl \
    && wget -P /tmp https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon/centreon-2.6.6.tar.gz \
    && cd /tmp \
    && tar xzf centreon-2.6.6.tar.gz \
    && cd /tmp/centreon-2.6.6 \
    && mkdir -p /usr/local/nagios/etc \
    && mkdir -p /usr/local/nagios/var \
    && ./install.sh -f /centreon-silent-install.txt \
    && rm -f /centreon-silent-install.txt \
#    && chown centreon-broker: /etc/centreon-broker \
#    && chmod 775 /etc/centreon-broker \
#    && chmod -R 775 /etc/centreon-engine \
#    && chmod 775 /var/lib/centreon-broker \
#    && rm -rf /tmp/centreon-2.6.6 \
#    && rm -f /tmp/centreon-2.6.6.tar.gz \
#    && service sudo restart \
#    && cd /usr/lib/nagios/plugins \
#    && chown centreon:centreon-engine centreon* \
#    && chown -R centreon:centreon-engine Centreon* \
#    && chown centreon:centreon-engine check_centreon* \
#    && chown centreon:centreon-engine check_snmp* \
#    && chown centreon:centreon-engine submit* \
#    && chown centreon:centreon-engine process* \
#    && chmod 664 centreon.conf \
#    && chmod +x centreon.pm \
#    && chmod +x Centreon/SNMP/Utils.pm \
#    && chmod +x check_centreon* \
#    && chmod +x check_snmp* \
#    && chmod +x submit* \
#    && chmod +x process* \
    && chmod 755 /start.sh \
    && chmod 755 /etc/apache2/foreground.sh \
    && rm -rf /tmp/snmp-mibs-downloader-1.1

VOLUME /var/lib/centreon /etc/centreon /usr/local/nagios/etc /usr/local/nagios/var

EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
