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
  echo "  server <start/stop>    Start/stop the server"
  echo "  client [script]        Start an interactive shell without a script"
  echo "                         or run a script with a batch shell"
  echo ""
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

BASEDIR=`dirname ${PRG}`
BASEDIR=`cd ${BASEDIR}/..;pwd`

echo "Sqoop home directory: ${BASEDIR}"

MapRHomeDir=/opt/mapr
hadoopVersionFile="${MapRHomeDir}/conf/hadoop_version"

cat ${BASEDIR}/server/conf/catalina.properties | egrep -v -e '^common.loader' > ${BASEDIR}/server/conf/catalina.properties.tmp
cp -f ${BASEDIR}/server/conf/catalina.properties.tmp ${BASEDIR}/server/conf/catalina.properties
cat ${BASEDIR}/server/conf/sqoop.properties | egrep -v -e '^org.apache.sqoop.submission.engine.mapreduce.configuration.directory' > ${BASEDIR}/server/conf/sqoop.properties.tmp
cp -f ${BASEDIR}/server/conf/sqoop.properties.tmp ${BASEDIR}/server/conf/sqoop.properties
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
if [ "$hadoop_mode" = "yarn" ]; then
	echo "common.loader=\${catalina.base}/lib,\${catalina.base}/lib/*.jar,\${catalina.home}/lib,\${catalina.home}/lib/*.jar,\${catalina.home}/../lib/*.jar,${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/share/hadoop/common/*.jar,${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/share/hadoop/hdfs/*.jar,${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/share/hadoop/mapreduce/*.jar,${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/share/hadoop/yarn/*.jar,${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/share/hadoop/tools/lib/*.jar,${MapRHomeDir}/lib/*.jar" >> ${BASEDIR}/server/conf/catalina.properties
  echo "org.apache.sqoop.submission.engine.mapreduce.configuration.directory=${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/etc/hadoop/" >> ${BASEDIR}/server/conf/sqoop.properties
elif [ "$hadoop_mode" = "classic" ]; then
	echo "common.loader=\${catalina.base}/lib,\${catalina.base}/lib/*.jar,\${catalina.home}/lib,\${catalina.home}/lib/*.jar,\${catalina.home}/../lib/*.jar,${MapRHomeDir}/hadoop/${HADOOP_ClASSIC_VERSION}/*.jar,${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/share/hadoop/common/lib/*.jar,${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/share/hadoop/common/*.jar,${MapRHomeDir}/hadoop/${HADOOP_YARN_VERSION}/share/hadoop/hdfs/*.jar,${MapRHomeDir}/hadoop/${HADOOP_ClASSIC_VERSION}/lib/hadoop-0.20.2-dev-capacity-scheduler.jar,${MapRHomeDir}/hadoop/${HADOOP_ClASSIC_VERSION}/lib/hadoop-${classic_version}-dev-core.jar,${MapRHomeDir}/hadoop/${HADOOP_ClASSIC_VERSION}/lib/hadoop-${classic_version}-dev-fairscheduler.jar" >> ${BASEDIR}/server/conf/catalina.properties
  echo "org.apache.sqoop.submission.engine.mapreduce.configuration.directory=${MapRHomeDir}/hadoop/${HADOOP_ClASSIC_VERSION}/conf/" >> ${BASEDIR}/server/conf/sqoop.properties
fi

CATALINA_BIN=${CATALINA_BIN:-${BASEDIR}/server/bin}
CLIENT_LIB=${CLIENT_LIB:-${BASEDIR}/shell/lib}

export CATALINA_PID="${CATALINA_BIN}/catalina.pid"

setup_catalina_opts() {
  # The Java System properties 'sqoop.http.port' and 'sqoop.admin.port' are
  # not used by Sqoop. They are used in Tomcat's server.xml configuration file
  echo "Using   CATALINA_OPTS:       ${CATALINA_OPTS}"

  catalina_opts="-Dsqoop.http.port=${SQOOP_HTTP_PORT}";
  catalina_opts="${catalina_opts} -Dsqoop.admin.port=${SQOOP_ADMIN_PORT}";

  echo "Adding to CATALINA_OPTS:    ${catalina_opts}"

  export CATALINA_OPTS="${CATALINA_OPTS} ${catalina_opts}"
}

COMMAND=$1
case $COMMAND in
  tool)
    if [ $# = 1 ]; then
      echo "Usage: sqoop.sh tool TOOL_NAME [TOOL_ARGS]"
      exit
    fi

    source ${BASEDIR}/bin/sqoop-sys.sh
    setup_catalina_opts

    # Remove the "tool" keyword from the command line and pass the rest
    shift

    $CATALINA_BIN/tool-wrapper.sh -server org.apache.sqoop.tomcat.TomcatToolRunner $@
    ;;
  server)
    if [ $# = 1 ]; then
      echo "Usage: sqoop.sh server <start/stop>"
      exit
    fi
    actionCmd=$2

    case $actionCmd in
      status)
        if [ ! -z "$CATALINA_PID" ]; then
          if [ -f "$CATALINA_PID" ]; then
            if [ -s "$CATALINA_PID" ]; then
              if [ -r "$CATALINA_PID" ]; then
                PID=`cat "$CATALINA_PID"`
                ps -p $PID >/dev/null 2>&1
                if [ $? -eq 0 ] ; then
                  echo "Tomcat is running with PID $PID."
                  exit 0
                fi
              fi
            fi
          fi
        fi
        echo "Most likely Tomcat is not running"
        exit 1

        ;;
      *)
        source ${BASEDIR}/bin/sqoop-sys.sh
        setup_catalina_opts

        # There seems to be a bug in catalina.sh whereby catalina.sh doesn't respect
        # CATALINA_OPTS when stopping the tomcat server. Consequently, we have to hack around
        # by specifying the CATALINA_OPTS properties in JAVA_OPTS variable
        if [ "$actionCmd" == "stop" ]; then
          export JAVA_OPTS="$JAVA_OPTS $CATALINA_OPTS"
        fi

        # Remove the first 2 command line arguments (server and action command (start/stop)) so we can pass
        # the rest to catalina.sh script
        shift
        shift

        $CATALINA_BIN/catalina.sh $actionCmd "$@"
        ;;
    esac
    ;;

  client)
    # Build class path with full path to each library
    for f in $CLIENT_LIB/*.jar; do
      CLASSPATH="${CLASSPATH}:$f"
    done

    EXEC_JAVA='java'
    if [ -n "${JAVA_HOME}" ] ; then
        EXEC_JAVA="${JAVA_HOME}/bin/java"
    fi
    ${EXEC_JAVA} -Djava.security.auth.login.config=${MapRHomeDir}/conf/mapr.login.conf -classpath ${CLASSPATH} org.apache.sqoop.shell.SqoopShell $2
    ;;

  *)
    echo "Command is not recognized."
    ;;
esac
