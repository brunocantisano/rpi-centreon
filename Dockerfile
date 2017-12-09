FROM resin/rpi-raspbian:latest
MAINTAINER Bruno Cardoso Cantisano <bruno.cantisano@gmail.com>

LABEL Centreon container for Raspberry Pi

RUN apt-get update \
#Centreon-Clib 
    && apt-get install build-essential wget cmake -y \
    && cd \
    && wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-clib/centreon-clib-1.4.2.tar.gz \
    && tar xzf centreon-clib-1.4.2.tar.gz \
    && cd centreon-clib-1.4.2/build \
    && cmake \
       -DWITH_TESTING=0 \
       -DWITH_PREFIX=/usr  \
       -DWITH_SHARED_LIB=1 \
       -DWITH_STATIC_LIB=0 \
       -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig . \
    && make && make install 
#Centreon Perl Connector 
    RUN apt-get install libperl-dev -y \
    && cd \
    && wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-connectors/centreon-connector-1.1.2.tar.gz \
    && tar xzf centreon-connector-1.1.2.tar.gz \
    && cd centreon-connector-1.1.2/perl/build \
    && cmake \
       -DWITH_PREFIX=/usr \
       -DWITH_PREFIX_BINARY=/usr/lib/centreon-connector  \
       -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include \
       -DWITH_TESTING=0 . \
    && make && make install 
#Centreon SSH Connector 
    RUN apt-get install libssh2-1-dev libgcrypt11-dev -y \
    && cd ~/centreon-connector-1.1.2/ssh/build \
    && cmake \
       -DWITH_PREFIX=/usr \
       -DWITH_PREFIX_BINARY=/usr/lib/centreon-connector  \
       -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include \
       -DWITH_TESTING=0 . \
    && make && make install 
#Centreon-Engine 
    RUN groupadd -g 6001 centreon-engine \
    && useradd -u 6001 -g centreon-engine -m -r -d /var/lib/centreon-engine -c "Centreon-engine Admin" -s /bin/bash centreon-engine \
    && apt-get install libcgsi-gsoap-dev libssl-dev libxerces-c-dev -y \
    && cd \
    && wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-engine/centreon-engine-1.4.15.tar.gz \
    && tar xzf centreon-engine-1.4.15.tar.gz \
    && cd centreon-engine-1.4.15/build/ \
    && cmake  \
       -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include  \
       -DWITH_CENTREON_CLIB_LIBRARY_DIR=/usr/lib  \
       -DWITH_PREFIX=/usr  \
       -DWITH_PREFIX_BIN=/usr/sbin  \
       -DWITH_PREFIX_CONF=/etc/centreon-engine  \
       -DWITH_USER=centreon-engine  \
       -DWITH_GROUP=centreon-engine  \
       -DWITH_LOGROTATE_SCRIPT=1 \
       -DWITH_VAR_DIR=/var/log/centreon-engine  \
       -DWITH_RW_DIR=/var/lib/centreon-engine/rw  \
       -DWITH_STARTUP_DIR=/etc/init.d  \
       -DWITH_PKGCONFIG_SCRIPT=1 \
       -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig  \
       -DWITH_TESTING=0  \
       -DWITH_ENABLE_PRECOMPILED_HEADERS=OFF \
       -DWITH_WEBSERVICE=1 . \
    && make && make install \
    && update-rc.d centengine defaults 
#Plugins Nagios 
    RUN apt-get install nagios-plugins-basic -y \
    && chown root:centreon-engine /usr/lib/nagios/plugins/check_icmp \
    && chmod u+s /usr/lib/nagios/plugins/check_icmp 
#Centreon-Broker
    RUN groupadd -g 6002 centreon-broker \
    && useradd -u 6002 -g centreon-broker -m -r -d /var/lib/centreon-broker -c "Centreon-broker Admin"  -s /bin/bash centreon-broker \
    && usermod -aG centreon-broker centreon-engine \
    && apt-get install librrd-dev libqt4-dev libqt4-sql-mysql libgnutls28-dev lsb-release -y \
    && cd \
    && wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-broker/centreon-broker-2.10.1.tar.gz \
    && tar xzf centreon-broker-2.10.1.tar.gz \
    && cd centreon-broker-2.10.1/build/ \
    && cmake \
       -DWITH_DAEMONS='central-broker;central-rrd' \
       -DWITH_GROUP=centreon-broker \
       -DWITH_PREFIX=/usr  \
       -DWITH_PREFIX_BIN=/usr/sbin  \
       -DWITH_PREFIX_CONF=/etc/centreon-broker  \
       -DWITH_PREFIX_LIB=/usr/lib/centreon-broker \
       -DWITH_PREFIX_MODULES=/usr/share/centreon/lib/centreon-broker \
       -DWITH_STARTUP_DIR=/etc/init.d \
       -DWITH_STARTUP_SCRIPT=auto \
       -DWITH_TESTING=0 \
       -DWITH_USER=centreon-broker . \
    && make && make install \
    && update-rc.d cbd defaults 
#SNMP
    RUN apt-get install -y snmp snmpd libnet-snmp-perl libsnmp-perl snmptrapd

WORKDIR /tmp/

#instalacao do mibs
    RUN apt-get install -y smistrip \
    && wget http://archive.ubuntu.com/ubuntu/pool/multiverse/s/snmp-mibs-downloader/snmp-mibs-downloader_1.1.tar.gz \
    && tar -xvf snmp-mibs-downloader_1.1.tar.gz \
    && rm -rf snmp-mibs-downloader_1.1.tar.gz \
    && mkdir -p /etc/snmp-mibs-downloader \
    && mkdir -p /usr/share/doc/mibrfcs \
    && mkdir -p /usr/share/doc/mibiana \
    && mkdir -p /usr/share/mibs/ietf \
    && mkdir -p /usr/share/mibs/iana \
    && cd /tmp/snmp-mibs-downloader-1.1 \
    && make install \
    && ln -s /usr/share/mibs/ /usr/share/snmp/mibs \
    && rm -rf /tmp/snmp-mibs-downloader-1.1

COPY files/snmpd.conf /etc/snmp/snmpd.conf
COPY files/snmp.conf /etc/snmp/snmp.conf
COPY files/default_snmpd.conf /etc/default/snmpd.conf
COPY files/default_snmptrapd /etc/default/snmptrapd

    RUN service snmpd restart \
    && service snmptrapd restart \
    && snmpwalk -c public -v 2c localhost

RUN groupadd -g 6000 centreon \
    && useradd -u 6000 -g centreon -m -r -d /var/lib/centreon -c "Centreon Admin" -s /bin/bash centreon \
    && usermod -aG centreon-engine centreon \
    && usermod -aG centreon-broker centreon \
    && usermod -aG centreon centreon-engine \
    && usermod -aG centreon centreon-broker \
    && echo centreon:centreon | /usr/sbin/chpasswd

RUN apt-get install -y sudo apache2 librrds-perl libconfig-inifiles-perl \
    libnet-snmp-perl libdigest-hmac-perl libcrypt-des-ede3-perl \
    libdbd-sqlite3-perl

RUN wget https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon/centreon-2.6.6.tar.gz \
    && tar xzf centreon-2.6.6.tar.gz \
    && cd centreon-2.6.6 

COPY files/centreon-silent-install.txt /tmp/centreon-2.6.6/centreon-silent-install.txt

RUN apt-get install -y librrds-perl rrdtool mailutils php5 php-pear php5-mysql \
    && mkdir -p /usr/lib/nagios/plugins \
    && mkdir -p /usr/local/nagios/log \
    && rm -f /tmp/centreon-2.6.6.tar.gz \
    && useradd -G centreon nagios \
    && usermod -G nagios www-data \
    && usermod -G nagios centreon \
    && echo nagios:nagios | /usr/sbin/chpasswd \
    && cd /tmp/centreon-2.6.6/ \
    && ./install.sh -f centreon-silent-install.txt \
    && chown centreon-broker: /etc/centreon-broker \
    && chmod 775 /etc/centreon-broker \
    && chmod -R 775 /etc/centreon-engine \
    && chmod 775 /var/lib/centreon-broker

COPY files/sudoers_centreon /etc/sudoers.d/centreon

RUN service sudo restart \
    && cd /usr/lib/nagios/plugins \
    && chown centreon:centreon-engine centreon* \
    && chown -R centreon:centreon-engine Centreon* \
    && chown centreon:centreon-engine check_centreon* \
    && chown centreon:centreon-engine check_snmp* \
    && chown centreon:centreon-engine submit* \
    && chown centreon:centreon-engine process* \
    && chmod 664 centreon.conf \
    && chmod +x centreon.pm \
    && chmod +x Centreon/SNMP/Utils.pm \
    && chmod +x check_centreon* \
    && chmod +x check_snmp* \
    && chmod +x submit* \
    && chmod +x process* 

RUN sed -i 's/DAEMON=\/usr\/local\/centreon\/bin\/centreontrapd/DAEMON=\/usr\/share\/centreon\/bin\/centreontrapd/g' /etc/init.d/centreontrapd \
    && sed -i 's/PIDFILE=\/var\/run\/centreon\/centreontrapd.pid/PIDFILE=\/var\/run\/centreontrapd.pid/g' /etc/init.d/centreontrapd

COPY files/conf.pm /etc/centreon/conf.pm
COPY files/centreontrapd.pm /etc/centreon/centreontrapd.pm

RUN chmod 775 /var/log/centreon \
    && chown centreon: /var/log/centreon \
    && service centreontrapd restart

COPY files/run.sh /run.sh

RUN chmod 755 /run.sh

EXPOSE 80

VOLUME /usr/lib/nagios/plugins /var/log/nagios /usr/local/nagios/bin/nagios /usr/local/nagios/etc/

CMD ["/run.sh"]
