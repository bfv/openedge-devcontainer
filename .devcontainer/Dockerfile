FROM docker.io/devbfvio/openedge-compiler:12.8.0

RUN apt-get update && apt-get install -y xz-utils
RUN apt-get install git -y
RUN apt-get install vim -y

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV PATH=$DLC:$DLC/bin:$PATH

# this script is build as docker.io/devbfvio/openedge-devcontainer:12.8.0
