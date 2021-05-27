#!/usr/bin/env bash
set -o errexit -o pipefail
 
[[ -z $DOMINO_USE_SUBDOMAIN ]] && DOMINO_USE_SUBDOMAIN=false

SAS_INSTALL_PATH=/usr/local/SASHome
#SAS_WORKDIR=/domino/saswork
#SAS_UTILDIR=/domino/sasutil
DOMINO_GIT_REPOS_PATH=/repos
DOMINO_DATASETS_PATH=/domino/datasets
 
USERMODS_FILE="`find $SAS_INSTALL_PATH -name sasv9_usermods.cfg | grep -v template_`"
WEBCONFIG_FILE="`find $SAS_INSTALL_PATH -wholename '*/war/config/config.properties'`"
SHORTCUTS_FILE="$SAS_INSTALL_PATH/SASFoundation/9.4/GlobalStudioSettings/shortcuts.xml"
 
mkdir -p $SAS_INSTALL_PATH/SASFoundation/9.4/GlobalStudioSettings
 
# Add saswork and sasutil to high performance volume
# This is recommended by the SAS team to ensure SAS Studio performs effeciently
#  with larger data sets.
# Uncomment section below if you have a higher performance volume attached to
#  Domino executors.
#sudo mkdir -p $SAS_WORKDIR $SAS_UTILDIR
#sudo chown -R $DOMINO_USER_NAME:$DOMINO_USER_NAME $SAS_WORKDIR $SAS_UTILDIR
#echo "-WORK $SAS_WORKDIR" >> $USERMODS_FILE
#echo "-UTILLOC $SAS_UTILDIR" >> $USERMODS_FILE
 
# Modify SASHOME variable to be $SAS_INSTALL_PATH
# TODO: Investigate if this is necessary
#echo "-SET SASHOME \"$SAS_INSTALL_PATH\"" >> $USERMODS_FILE
 
# Hack to ensure autoexec.sas can live in the Domino project folder.
# This is needed to properly tie in autoexec.sas with SAS Studio
ln -s "$DOMINO_WORKING_DIR/autoexec.sas" "/home/$DOMINO_USER_NAME/autoexec.sas"
 
# Configure the SAS Studio working directory
sed -i "s#webdms.customPathRoot=#webdms.customPathRoot=$DOMINO_WORKING_DIR#g" $WEBCONFIG_FILE
 
# Configure SAS Studio folder shortcuts to show Domino Git repos and Datasets folders
echo '<?xml version="1.0" encoding="UTF-8"?><Shortcuts>' >> $SHORTCUTS_FILE
if [ -d "$DOMINO_GIT_REPOS_PATH" ]; then
    echo "  <Shortcut type=\"disk\" name=\"Git Repos\" dir=\"$DOMINO_GIT_REPOS_PATH\" />" >> $SHORTCUTS_FILE
fi
if [ -d "$DOMINO_DATASETS_PATH" ]; then
    echo "  <Shortcut type=\"disk\" name=\"Domino Datasets\" dir=\"$DOMINO_DATASETS_PATH\" />" >> $SHORTCUTS_FILE
fi
for DOMINO_IMPORT in `printenv | grep -e 'DOMINO_.*_WORKING_DIR' | tr '=' ' ' | awk '{print $1}'`; do
    DOMINO_IMPORT_DIR=${!DOMINO_IMPORT}
    DOMIMO_IMPORT_NAME=`echo "Import $DOMINO_IMPORT_DIR" | sed 's#/mnt/##g'`
    echo "  <Shortcut type=\"disk\" name=\"$DOMIMO_IMPORT_NAME\" dir=\"$DOMINO_IMPORT_DIR\" />" >> $SHORTCUTS_FILE
done
echo '</Shortcuts>' >> $SHORTCUTS_FILE

# Change the URL path to avoid requiring subdomains
if ! $DOMINO_USE_SUBDOMAIN; then
    PREFIX_PATH="${DOMINO_PROJECT_OWNER}/${DOMINO_PROJECT_NAME}/notebookSession/${DOMINO_RUN_ID}"
    PREFIX_FILE="${DOMINO_PROJECT_OWNER}#${DOMINO_PROJECT_NAME}#notebookSession#${DOMINO_RUN_ID}"

    sed -i "s#path=\"/SASStudio\"#path=\"/${PREFIX_PATH}\"#g" ${SAS_INSTALL_PATH}/sas/appserver/studio/conf/Catalina/localhost/SASStudio.xml
    mv ${SAS_INSTALL_PATH}/sas/appserver/studio/conf/Catalina/localhost/SASStudio.xml ${SAS_INSTALL_PATH}/sas/appserver/studio/conf/Catalina/localhost/${PREFIX_FILE}#SASStudio.xml
fi
 
# Start SAS Studio and idle while it runs
sudo -E bash -c "$SAS_INSTALL_PATH/sas/sasstudio.sh start && while true ; do :; sleep 60 ; done"
