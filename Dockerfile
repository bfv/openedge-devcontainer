# the Dockerfile for the actual devcontainer

FROM docker.io/devbfvio/openedge-compiler:12.8.9.1-dotnet10

USER root
ENV DEBIAN_FRONTEND=noninteractive

# devcontainer needs to /home/openedge
# and the openedge user needs to be able to write there
RUN mkdir -p /home/openedge && \
    chown openedge:openedge /home/openedge
    
RUN apt-get update -y && apt install -y xz-utils 
RUN apt-get install -y ca-certificates gnupg git --fix-missing -v
RUN apt-get install vim -y --fix-missing -v
RUN apt-get install curl wget iputils-ping net-tools dnsutils -y

RUN apt-get -o Dpkg::Options::="--force-confold" install -y netbase iptables && \
    apt-get clean -y
    
RUN rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV PATH=$DLC:$DLC/bin:$PATH

RUN echo "\n# custom entries:" >> /usr/dlc/startup.pf && \ 
    echo "-clrnetcore" >> /usr/dlc/startup.pf && \
    echo "-preloadCLR" >> /usr/dlc/startup.pf && \
    # echo "-debugReady 3099" >> /usr/dlc/startup.pf && \
    chown root:openedge /usr/dlc/startup.pf

RUN /usr/dlc/bin/proDebugEnable -enable-all

#USER openedge

# this script is build as docker.io/devbfvio/openedge-devcontainer:12.8.9.1
