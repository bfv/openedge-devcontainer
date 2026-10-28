# the Dockerfile for the actual devcontainer

FROM docker.io/devbfvio/openedge-compiler:12.8.12-1-dotnet10

USER root
ENV DEBIAN_FRONTEND=noninteractive

# devcontainer needs to /home/openedge
# and the openedge user needs to be able to write there
RUN mkdir -p /home/openedge/.local/bin && \
    chown --recursive openedge:openedge /home/openedge 

RUN rm -f /etc/protocols 

RUN apt-get update && apt-get install -y software-properties-common 
RUN add-apt-repository -y ppa:git-core/ppa 

RUN apt-get update -y && apt install -y xz-utils 
RUN apt-get install -y ca-certificates gnupg git --fix-missing 
RUN apt-get install vim -y --fix-missing 
RUN apt-get install -y make
RUN apt-get install -y \
    curl \
    wget \
    iputils-ping \
    net-tools \
    dnsutils \
    iproute2 \
    netcat-openbsd \
    lsof \
    procps \
    htop \
    jq \
    less \
    unzip \
    zip \
    bash-completion \
    shellcheck

RUN apt-get -o Dpkg::Options::="--force-confold" install -y netbase iptables && \
    apt-get clean -y

RUN rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV HOME=/home/openedge
ENV PATH=$DLC:$DLC/bin:$HOME/.local/bin:$PATH

RUN chown root:openedge /usr/dlc/startup.pf

RUN /usr/dlc/bin/proDebugEnable -enable-all

USER openedge

# this script is built as docker.io/devbfvio/openedge-devcontainer:12.8.12-3

