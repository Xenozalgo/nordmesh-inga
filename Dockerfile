FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy
LABEL maintainer="Julio Gutierrez julio.guti+nordvpn@pm.me"

ARG NORDVPN_VERSION=6.0.2
ARG DEBIAN_FRONTEND=noninteractive

# iptables is no longer a dependency of nordvpn (>= 5.x uses nftables) but the cont-init scripts need it
RUN apt-get update -y && \
    apt-get install -y curl iputils-ping iptables libc6 wireguard vim && \
    curl https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn-release/nordvpn-release_1.0.0_all.deb --output /tmp/nordrepo.deb && \
    apt-get install -y /tmp/nordrepo.deb && \
    apt-get update -y && \
    apt-get install -y nordvpn${NORDVPN_VERSION:+=$NORDVPN_VERSION} && \
    apt-get remove -y nordvpn-release && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    rm -rf \
		/tmp/* \
		/var/cache/apt/archives/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

COPY /rootfs /
RUN chmod +x /etc/cont-init.d/* /etc/services.d/nordvpn/run /etc/services.d/nordvpn/finish \
    /etc/services.d/nordvpn/data/check /usr/bin/dockerNetworks /usr/bin/dockerNetworks6 \
    /usr/bin/nord_config /usr/bin/nord_connect /usr/bin/nord_login /usr/bin/nord_migrate /usr/bin/nord_watch \
    /usr/bin/healthcheck

HEALTHCHECK --interval=60s --timeout=15s --start-period=120s \
            CMD /usr/bin/healthcheck

ENV S6_CMD_WAIT_FOR_SERVICES=1
CMD nord_login && nord_config && nord_connect && nord_migrate && nord_watch
