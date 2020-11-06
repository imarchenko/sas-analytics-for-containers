FROM dominodatalab/base:DMD_py3.7_r4.0.2_2020q3

ARG SAS_LOCAL_PATH=./SAS_Studio/
ARG SAS_INSTALL_PATH=/usr/local/SASHome/
ARG SAS_LINK_PATH=/opt/sasinside/
ARG DOMINO_USER_NAME=ubuntu
ARG DOMINO_USER_PASSWORD=domino
ARG SCRIPTS_PATH=/var/opt/workspaces/sa4c
ARG INSTALL_SCRIPT=$SCRIPTS_PATH/install
ARG START_SCRIPT=$SCRIPTS_PATH/start

USER root

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install system dependencies
RUN apt-get update && \
    apt-get install -y numactl

# Add SA4C Installation
COPY --chown=ubuntu:ubuntu $SAS_LOCAL_PATH $SAS_INSTALL_PATH
#ADD $SAS_LOCAL_PATH $SAS_INSTALL_PATH
#RUN chown -R $DOMINO_USER_NAME:$DOMINO_USER_NAME $SAS_INSTALL_PATH

# Add script to help launch SAS batch scripts
ADD run_sas.sh /usr/bin/run_sas.sh
RUN chmod 755 /usr/bin/run_sas.sh

# Give Domino run user sudo access to be able to launch SAS
# * Need to investigate if this is necessary
RUN echo "$DOMINO_USER_NAME    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Change password for DOMINO_USER_NAME
RUN echo "$DOMINO_USER_NAME:$DOMINO_USER_PASSWORD" | chpasswd

# Run Domino SA4C install script
RUN mkdir -p $SCRIPTS_PATH
ADD install.sh $INSTALL_SCRIPT
ADD start.sh $START_SCRIPT
RUN chmod 755 $INSTALL_SCRIPT $START_SCRIPT && \
    $INSTALL_SCRIPT
