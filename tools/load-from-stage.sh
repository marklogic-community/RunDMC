#!/bin/sh

if [ "$#" -ne 3 ]; then
    echo "Usage: load-from-stage.sh hostname xdbc-port user:pass"
    exit -1
fi

    TARGET_FILE=$0
    cd `dirname $TARGET_FILE`
    TARGET_FILE=`basename $TARGET_FILE`
    
    # Iterate down a (possible) chain of symlinks
    while [ -L "$TARGET_FILE" ]
    do
        TARGET_FILE=`readlink $TARGET_FILE`
        cd `dirname $TARGET_FILE`
        TARGET_FILE=`basename $TARGET_FILE`
    done
    
    # Compute the canonicalized name by finding the physical path 
    # for the directory we're in and appending the target file.
    PHYS_DIR=`pwd -P`
    RESULT=$PHYS_DIR/$TARGET_FILE

BASE=$PHYS_DIR

CP=$BASE/lib/xcc.jar
CP=$CP:$BASE/lib/xstream-1.3.1.jar
CP=$CP:$BASE/lib/xqsync.jar

if [ -d "$JAVA_HOME" ]; then
  JAVA=$JAVA_HOME/bin/java
else
  JAVA=java
fi

F=dmc-stage.marklogic.com:8007
T=${1}:${2}
# And some credentials
FCREDS='reader:read3r'
TCREDS=${3}

FROM=$F
TO=$T
FROMCREDS=$FCREDS
TOCREDS=$TCREDS

DIRS="/"
DOCS=""

read -p "Loading All URIS under / from $FROM to $TO  (as $TCREDS) Continue? [n] " yesno
shopt -s nocasematch
case "$yesno" in
  y|Y|Yes) ;;
  * ) echo "Aborted"; exit -1 ;;
esac

echo "Copying $FROM to $TO"
$JAVA -cp $CP -Dfile.encoding=UTF-8 -DLOG_LEVEL=ALL \
    -DLOG_HANDLER=FILE \
    -DINPUT_CONNECTION_STRING=xcc://$FROMCREDS@$FROM/RunDMC \
    -DOUTPUT_CONNECTION_STRING=xcc://$TOCREDS@$TO/RunDMC \
    -DINPUT_DIRECTORY_URI="$DIRS" \
    com.marklogic.ps.xqsync.XQSync 

#cleanup
