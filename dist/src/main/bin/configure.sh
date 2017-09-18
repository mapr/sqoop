#!/bin/bash

MAPR_HOME="${BASEMAPR:-/opt/mapr}"
MAPR_CONF_DIR="${MAPR_HOME}/conf"
MAPR_CONF_WARDEN_DIR="${MAPR_CONF_DIR}/conf.d"
DAEMON_CONF="$MAPR_HOME/conf/daemon.conf"
SQOOP_VERSION="2.0.0"
SQOOP_HOME="$MAPR_HOME"/sqoop/sqoop-"$SQOOP_VERSION"
SQOOP_CONF_DIR="${SQOOP_HOME}"/conf
SQOOP_WARDEN_FILE="${SQOOP_HOME}"/conf.d/warden.sqoop2.conf
SQOOP_CONF_FILE="${SQOOP_CONF_DIR}"/sqoop.properties
secureCluster=0
MAPR_USER=""
MAPR_GROUP=""

# isSecure is set in server/configure.sh
if [ -n "$isSecure" ]; then
    if [ "$isSecure" == "true" ]; then
        secureCluster=1
    fi
fi

changeSqoopPermission() {
  if [ -f "$DAEMON_CONF" ]; then
    MAPR_USER=$( awk -F = '$1 == "mapr.daemon.user" { print $2 }' "$DAEMON_CONF")
    MAPR_GROUP=$( awk -F = '$1 == "mapr.daemon.group" { print $2 }' "$DAEMON_CONF")
  else
    MAPR_USER=`logname`
    MAPR_GROUP="$MAPR_USER"
  fi
  if [ ! -z "$MAPR_USER" ]; then
    chown -R "$MAPR_USER" "$MAPR_HOME/sqoop"
  fi
  if [ ! -z "$MAPR_GROUP" ]; then
    chgrp -R "$MAPR_GROUP" "$MAPR_HOME/sqoop"
  fi
}

#
# Copying the warden service config file
#
setupWardenConfFile() {
  if ! [ -d ${MAPR_CONF_WARDEN_DIR} ]; then
    mkdir -p ${MAPR_CONF_WARDEN_DIR} > /dev/null 2>&1
  fi

  # Install warden file
  cp ${SQOOP_WARDEN_FILE} ${MAPR_CONF_WARDEN_DIR}
}

createRestartFile(){
  if ! [ -d ${MAPR_CONF_DIR}/restart ]; then
    mkdir -p ${MAPR_CONF_DIR}/restart
  fi

  echo "maprcli node services -action restart -name sqoop2 -nodes $(hostname)" > "${MAPR_CONF_DIR}/restart/sqoop-$SQOOP_VERSION.restart"
  chown -R $MAPR_USER:$MAPR_GROUP "${MAPR_CONF_DIR}/restart/sqoop-$SQOOP_VERSION.restart"
}

#
# main
#
# typically called from core configure.sh
#

USAGE="usage: $0 [--secure|--customSecure|--unsecure|--help]"

if [ ${#} -gt 1 ]; then
  echo "$USAGE"
  return 1 2>/dev/null || exit 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --secure)
    secureCluster=1
    shift
    ;;
    --customSecure)
    secureCluster=1
    shift
    ;;
    --unsecure)
    secureCluster=0
    shift
    ;;
    --help)
    echo "$USAGE"
    return 0 2>/dev/null || exit 0
    ;;
    *)
      echo "$USAGE"
      return 1 2>/dev/null || exit 1
    ;;
  esac
done


# save secure state
echo $secureCluster > ${SQOOP_CONF_DIR}/isSecure

# remove state file
if [ -f "$SQOOP_HOME/conf/.not_configured_yet" ]; then
    rm -f "$SQOOP_HOME/conf/.not_configured_yet"
fi

changeSqoopPermission
createRestartFile
setupWardenConfFile

true