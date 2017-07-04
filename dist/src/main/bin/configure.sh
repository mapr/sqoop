#!/bin/bash

MAPR_HOME="${BASEMAPR:-/opt/mapr}"
MAPR_CONF_DIR="${MAPR_HOME}/conf/conf.d"
DAEMON_CONF="$MAPR_HOME/conf/daemon.conf"
SQOOP_VERSION="2.0.0"
SQOOP_HOME="$MAPR_HOME"/sqoop/sqoop-"$SQOOP_VERSION"
SQOOP_CONF_DIR="${SQOOP_HOME}"/conf
SQOOP_WARDEN_FILE="${SQOOP_HOME}"/conf.d/warden.sqoop2.conf
SQOOP_CONF_FILE="${SQOOP_CONF_DIR}"/sqoop.properties
secureCluster=0

# isSecure is set in server/configure.sh
if [ -n "$isSecure" ]; then
    if [ "$isSecure" == "true" ]; then
        secureCluster=1
    fi
fi

changeSqoopPermission() {

  if [ -z "$MAPR_USER" ] ; then
    MAPR_USER=$( awk -F = '$1 == "mapr.daemon.user" { print $2 }' "$DAEMON_CONF")
  fi
  if [ -z "$MAPR_GROUP" ] ; then
    MAPR_GROUP=$( awk -F = '$1 == "mapr.daemon.group" { print $2 }' "$DAEMON_CONF")
  fi

  if [ -z "$MAPR_USER" ] ; then
    MAPR_USER=mapr
  fi
  if [ -z "$MAPR_GROUP" ] ; then
    MAPR_GROUP=mapr
  fi

  if [ -f "$DAEMON_CONF" ]; then
    if [ ! -z "$MAPR_USER" ]; then
      chown -R "$MAPR_USER" "$SQOOP_HOME"
    fi
    if [ ! -z "$MAPR_GROUP" ]; then
      chgrp -R "$MAPR_GROUP" "$SQOOP_HOME"
    fi
  fi
}

#
# Copying the warden service config file
#
setupWardenConfFile() {
  if ! [ -d ${MAPR_CONF_DIR} ]; then
    mkdir -p ${MAPR_CONF_DIR} > /dev/null 2>&1
  fi

  # Install warden file
  if [ ! -e ${MAPR_CONF_DIR}/warden.sqoop2.conf ]; then
    cp ${SQOOP_WARDEN_FILE} ${MAPR_CONF_DIR}
  fi
}

#
# main
#
# typically called from core configure.sh
#

USAGE="usage: $0 [--secure|--unsecure|--help]"

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


# Create sqoopversion file
echo "$SQOOP_VERSION" > "$MAPR_HOME"/sqoop/sqoopversion

# save secure state
echo $secureCluster > ${SQOOP_CONF_DIR}/isSecure


changeSqoopPermission

setupWardenConfFile

true