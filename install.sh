#!/bin/bash
# Environment variables referenced in this script need to be set in Dockerfile
set -o nounset -o errexit -o pipefail
 
WEBCONFIG_FILE="`find $SAS_INSTALL_PATH -wholename '*/war/config/config.properties'`"
 
# Create symbolic links to SAS_LINK_PATH due to sas-kernel
mkdir -p $SAS_LINK_PATH
ln -s $SAS_INSTALL_PATH $SAS_LINK_PATH
 
# Setup SAS binaries for easy access
ln -s $SAS_INSTALL_PATH/SASFoundation/9.4/bin/sas_en /usr/bin/sas
chmod +x /usr/bin/sas
 
# This was set up in prior SAS installs
# * Need to investigate if this is required
ln -sf /bin/bash /bin/sh
 
# Set up autologin for SAS Studio
sed -i "s#webdms.workspaceServer.autoLoginUser=#webdms.workspaceServer.autoLoginUser=${DOMINO_USER_NAME}#g" $WEBCONFIG_FILE
sed -i "s#webdms.workspaceServer.autoLoginPassword=#webdms.workspaceServer.autoLoginPassword=${DOMINO_USER_PASSWORD}#g" $WEBCONFIG_FILE
 
# Run SAS setuid script to ensure proper permissions are set to execute SAS
$SAS_INSTALL_PATH/SASFoundation/9.4/utilities/bin/setuid.sh
 
# Modify start script with updated SAS paths
sed -i "s#SAS_INSTALL_PATH=/usr/local/SASHome#SAS_INSTALL_PATH=$SAS_INSTALL_PATH#g" $START_SCRIPT
 
# Install Python dependencies for SAS
pip install sas_kernel saspy pandas numpy scipy
