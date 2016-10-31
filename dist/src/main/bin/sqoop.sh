#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
function print_usage(){
  echo "Usage: sqoop.sh COMMAND"
  echo "       where COMMAND is one of:"
  echo "  server <start/stop/status>              Start/stop the server"
  echo "  client [script] [--custom]       Start an interactive shell without a script"
  echo "                                   or run a script with a batch shell"
  echo "                                   option --custom set custom authentication"
  echo ""
}

function sqoop_server_classpath_set {

  HADOOP_COMMON_HOME=${HADOOP_COMMON_HOME:-${YARN_HOME}/share/hadoop/common}
  HADOOP_HDFS_HOME=${HADOOP_HDFS_HOME:-${YARN_HOME}/share/hadoop/hdfs}

  if [ "$hadoop_mode" = "yarn" ]; then
    HADOOP_MAPRED_HOME=${HADOOP_MAPRED_HOME:-${YARN_HOME}/share/hadoop/mapreduce}
    HADOOP_YARN_HOME=${HADOOP_YARN_HOME:-${YARN_HOME}/share/hadoop/yarn}

    if [[ ! (-d "${HADOOP_COMMON_HOME}" && -d "${HADOOP_HDFS_HOME}" && -d "${HADOOP_MAPRED_HOME}" && -d "${HADOOP_YARN_HOME}") ]]; then
      echo "Can't load the Hadoop related java lib, please check the setting for the following environment variables:"
      echo "    HADOOP_COMMON_HOME, HADOOP_HDFS_HOME, HADOOP_MAPRED_HOME, HADOOP_YARN_HOME"
      exit
    fi

    for f in $HADOOP_HDFS_HOME/lib/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done

    for f in $HADOOP_MAPRED_HOME/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done

    for f in $HADOOP_MAPRED_HOME/lib/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done

    for f in $HADOOP_YARN_HOME/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done

    for f in $HADOOP_YARN_HOME/lib/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done

  elif [ "$hadoop_mode" = "classic" ]; then
    HADOOP_CLASSIC_HOME=${HADOOP_CLASSIC_HOME:-${CLASSIC_HOME}}
    for f in $HADOOP_CLASSIC_HOME/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done
    for f in $HADOOP_CLASSIC_HOME/lib/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done
  fi

  for f in $SQOOP_SERVER_LIB/*.jar; do
    CLASSPATH="${CLASSPATH}:$f"
  done

  for f in $HADOOP_COMMON_HOME/*.jar; do
    CLASSPATH="${CLASSPATH}:$f"
  done

  for f in $HADOOP_COMMON_HOME/lib/*.jar; do
    CLASSPATH="${CLASSPATH}:$f"
  done

  for f in $HADOOP_HDFS_HOME/*.jar; do
    CLASSPATH="${CLASSPATH}:$f"
  done

  for f in $HIVE_HOME/lib/*.jar; do
    # exclude the jdbc for derby, to avoid the sealing violation exception
    if [[ ! $f =~ derby* && ! $f =~ jetty* ]]; then
      CLASSPATH="${CLASSPATH}:$f"
    fi
  done
}

function is_sqoop_server_running {
  if [[ -f "${sqoop_pidfile}" ]]; then
    kill -s 0 $(cat "$sqoop_pidfile") >/dev/null 2>&1
    return $?
  else
    return 1
  fi
}

function sqoop_extra_classpath_set {
  if [[ -n "${SQOOP_SERVER_EXTRA_LIB}" ]]; then
    for f in $SQOOP_SERVER_EXTRA_LIB/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done
  fi
}

if [ $# = 0 ]; then
  print_usage
  exit
fi

# resolve links - $0 may be a softlink
PRG="${0}"

while [ -h "${PRG}" ]; do
  ls=`ls -ld "${PRG}"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "${PRG}"`/"$link"
  fi
done

# Default configuration directory is relatively
DEFAULT_SQOOP_CONF_DIR=`dirname $0`/../conf
SQOOP_CONF_DIR=${SQOOP_CONF_DIR:-$DEFAULT_SQOOP_CONF_DIR}
echo "Setting conf dir: $SQOOP_CONF_DIR"

BASEDIR=`dirname ${PRG}`
BASEDIR=`cd ${BASEDIR}/..;pwd`
MAPR_CONF_DIR=/opt/mapr/conf
ENV_FILE=env.sh
export SQOOP2_HOST=$(hostname -f)

# MapR change. Source env.sh if it exists
if [[ -n $(find ${MAPR_CONF_DIR} -name "${ENV_FILE}" -print) ]]; then
    source ${MAPR_CONF_DIR}/env.sh
fi
SQOOP_IDENT_STRING=${SQOOP_IDENT_STRING:-$USER}
SQOOP_PID_DIR=${SQOOP_PID_DIR:-/tmp}
sqoop_pidfile="${SQOOP_PID_DIR}/sqoop-${SQOOP_IDENT_STRING}-jetty-server.pid"
JAVA_OPTS="$JAVA_OPTS -Dsqoop.config.dir=$SQOOP_CONF_DIR"
JAVA_OPTS="$JAVA_OPTS ${MAPR_AUTH_CLIENT_OPTS}"

echo "Sqoop home directory: ${BASEDIR}"

MapRHomeDir=/opt/mapr
hadoopVersionFile="${MapRHomeDir}/conf/hadoop_version"

if [ -f ${MapRHomeDir}/conf/hadoop_version ]
then
  hadoop_mode=`cat ${MapRHomeDir}/conf/hadoop_version | grep default_mode | cut -d '=' -f 2`
  yarn_version=`cat ${MapRHomeDir}/conf/hadoop_version | grep yarn_version | cut -d '=' -f 2`
  classic_version=`cat ${MapRHomeDir}/conf/hadoop_version | grep classic_version | cut -d '=' -f 2`
  HADOOP_YARN_VERSION="hadoop-$yarn_version"
  HADOOP_ClASSIC_VERSION="hadoop-$classic_version"
else
  echo 'Unknown hadoop version'
fi

cat ${BASEDIR}/conf/sqoop.properties | egrep -v -e '^org.apache.sqoop.submission.engine.mapreduce.configuration.directory' > ${BASEDIR}/conf/sqoop.properties.tmp
cp -f ${BASEDIR}/conf/sqoop.properties.tmp ${BASEDIR}/conf/sqoop.properties

if [ "$hadoop_mode" = "yarn" ]; then
  YARN_HOME=${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}
  echo "org.apache.sqoop.submission.engine.mapreduce.configuration.directory=${YARN_HOME}/etc/hadoop/" >> ${BASEDIR}/conf/sqoop.properties
elif [ "$hadoop_mode" = "classic" ]; then
  CLASSIC_HOME=${MapRHomeDir}/hadoop/${HADOOP_ClASSIC_VERSION}
  echo "org.apache.sqoop.submission.engine.mapreduce.configuration.directory=${CLASSIC_HOME}/conf/" >> ${BASEDIR}/conf/sqoop.properties
fi

SQOOP_CLIENT_LIB=${BASEDIR}/shell/lib
SQOOP_SERVER_LIB=${BASEDIR}/server/lib
SQOOP_TOOLS_LIB=${BASEDIR}/tools/lib

EXEC_JAVA='java'
if [ -n "${JAVA_HOME}" ] ; then
    EXEC_JAVA="${JAVA_HOME}/bin/java"
fi

# validation the java command
${EXEC_JAVA} -version 2>/dev/null
if [[ $? -gt 0 ]]; then
  echo "Can't find the path for java, please check the environment setting."
  exit
fi

sqoop_extra_classpath_set
COMMAND=$1
case $COMMAND in
  tool)
    if [ $# = 1 ]; then
      echo "Usage: sqoop.sh tool TOOL_NAME [TOOL_ARGS]"
      exit
    fi

    source ${BASEDIR}/bin/sqoop-sys.sh

    # Remove the "tool" keyword from the command line and pass the rest
    shift

    # Build class path with full path to each library,including tools ,server and hadoop related
    for f in $SQOOP_TOOLS_LIB/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done

    # Build class path with full path to each library, including hadoop related
    sqoop_server_classpath_set

    ${EXEC_JAVA} $JAVA_OPTS -classpath ${CLASSPATH} org.apache.sqoop.tools.ToolRunner $@
    ;;
  server)
    if [ $# = 1 ]; then
      echo "Usage: sqoop.sh server <start/stop/status>"
      exit
    fi

    source ${BASEDIR}/bin/sqoop-sys.sh

    case $2 in
      run)
        # For running in the foreground, we're not doing any checks if we're running or not and simply start the server)
        sqoop_server_classpath_set
        echo "Starting the Sqoop2 server..."
        exec ${EXEC_JAVA} $JAVA_OPTS -classpath ${CLASSPATH} org.apache.sqoop.server.SqoopJettyServer
        ;;
      start)
        # check if the sqoop server started already.
        is_sqoop_server_running
        if [[ $? -eq 0 ]]; then
          echo "The Sqoop server is already started."
          exit
        fi

        # Build class path with full path to each library, including hadoop related
        sqoop_server_classpath_set

        echo "Starting the Sqoop2 server..."
        ${EXEC_JAVA} $JAVA_OPTS -classpath ${CLASSPATH} org.apache.sqoop.server.SqoopJettyServer &

        echo $! > "${sqoop_pidfile}" 2>/dev/null
        if [[ $? -gt 0 ]]; then
          echo "ERROR:  Cannot write pid ${pidfile}."
        fi

        # wait 5 seconds, then check if the sqoop server started successfully.
        sleep 5
        is_sqoop_server_running
        if [[ $? -eq 0 ]]; then
          echo "Sqoop2 server started."
        fi
      ;;
      stop)
        # check if the sqoop server stopped already.
        is_sqoop_server_running
        if [[ $? -gt 0 ]]; then
          echo "No Sqoop server is running."
          exit
        fi

        pid=$(cat "$sqoop_pidfile")
        echo "Stopping the Sqoop2 server..."
        kill -9 "${pid}" >/dev/null 2>&1
        rm -f "${sqoop_pidfile}"
        echo "Sqoop2 server stopped."
      ;;
      status)
        # check sqoop server status.
        is_sqoop_server_running
        if [[ $? -eq 0 ]]; then
          echo "The Sqoop server started."
          exit 0
        else
          echo "The Sqoop server stopped."
          exit 1
        fi
      ;;
      *)
        echo "Unknown command, usage: sqoop.sh server <start/stop/status>"
        exit
      ;;
    esac
    ;;

  client)
     # Second argument may been security argument or script name
    if [[ $2 == --*  ]]; then
      SCRIPT_NAME=""
    else
      SCRIPT_NAME=$2
    fi

    MAPR_VERSION=`cat /opt/mapr/MapRBuildVersion | awk -F "." '{print $1"."$2}'`

    if [[ $2 == "--custom" ]] || [[ $3 == "--custom" ]]; then
      echo "Using MaprDelegationTokenAuthenticator"
      # if mapr-core release <= 5.0 then return 1, else return 0
      if [[ `echo | awk -v cur=$MAPR_VERSION -v min=5.0 '{if (cur <= min) printf("1"); else printf ("0");}'` -eq 1 ]]; then
        CUSTOM_AUTH_OPTS="-DauthClass=org.apache.sqoop.client.request.MaprDelegationTokenAuthenticator"
      else
        CUSTOM_AUTH_OPTS="-DauthClass=com.mapr.security.maprauth.MaprDelegationTokenAuthenticator"
      fi
    else
      echo "Using default authenticator"
      CUSTOM_AUTH_OPTS="-DauthClass=org.apache.hadoop.security.token.delegation.web.KerberosDelegationTokenAuthenticator"
    fi
    JAVA_OPTS="$JAVA_OPTS ${CUSTOM_AUTH_OPTS}"
   # Build class path with full path to each library
    for f in $SQOOP_CLIENT_LIB/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done

    for f in ${MapRHomeDir}/lib/*.jar; do
      # Remove slf4j jars for prevent conflicts with sqoop`s slf4j jars
      if [[ $f != *slf4j* ]]; then
        CLASSPATH="${CLASSPATH}:$f"
      fi
    done

    ${EXEC_JAVA} $JAVA_OPTS -Djava.security.auth.login.config=${MapRHomeDir}/conf/mapr.login.conf -classpath ${CLASSPATH} org.apache.sqoop.shell.SqoopShell $SCRIPT_NAME
    ;;

  *)
    echo "Command is not recognized."
    ;;
esac
