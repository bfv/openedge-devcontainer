# the Dockerfile for the actual devcontainer

FROM docker.io/devbfvio/openedge-compiler:12.8.4

USER root

RUN apt-get update && apt-get install -y xz-utils
RUN apt-get install git -y
RUN apt-get install vim -y
RUN apt-get install curl -y
RUN apt-get install wget -y
RUN apt-get install iputils-ping -y
RUN apt-get install net-tools -y
RUN apt-get install dnsutils -y

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV PATH=$DLC:$DLC/bin:$PATH

# this script is build as docker.io/devbfvio/openedge-devcontainer:12.8.4
