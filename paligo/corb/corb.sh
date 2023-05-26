#!/bin/bash
unset CLASSPATH
DIR="$( cd "$( dirname "$(realpath $0)" )" && pwd )"
VMARGS="-Dfile.encoding=UTF-8"
LIB_HOME=$DIR

for file in "${LIB_HOME}"/*.jar
do
  if [ ! -z "$CLASSPATH" ]; then
    CLASSPATH=${CLASSPATH}":"$file
  else
    CLASSPATH=$file
  fi
done
CLASSPATH=$DIR/conf:$CLASSPATH
java -cp "$CLASSPATH" $VMARGS $JVM_OPTS "$@" com.marklogic.developer.corb.Manager
