#!/usr/bin/env bash
#
# Install RunDMC apidoc component.
#
######################################################################

# look for GNU readlink first (OS X, BSD, Solaris)
READLINK=`type -P greadlink`
if [ -z "$READLINK" ]; then
    # if readlink is not GNU-style, setting BASE will fail
    READLINK=`type -P readlink`
fi
BASE=`$READLINK -f $0`
if [ -z "$BASE" ]; then
    BASE=`stat -f $0`
fi
BASE=`dirname $BASE`

set -e
if [ -d "$BASE" ]; then
    cd $BASE
else
    echo There were problems initializing the environment!
    echo Make sure you are running in the git clone directory.
fi
# In BSD stat -f returns a relative path.
# For app-server config we need an absolute path.
# We should now be in that directory.
BASE=`pwd`

echo
echo This script should run on a host where MarkLogic is already running.
echo
HOSTNAME=localhost

echo To get started we need your MarkLogic admin login.
read -p "Admin user: [admin] " ADMIN_USER
if [ -z "$ADMIN_USER" ]; then
    ADMIN_USER=admin
fi
read -s -p "Admin password: [admin] " ADMIN_PASSWORD
if [ -z "$ADMIN_PASSWORD" ]; then
    ADMIN_PASSWORD=admin
fi
echo
echo The docapp server needs to use two ports.
echo Be sure to select ports that are not already in use.
read -p "Application port: [8411] " PORT_MAIN
if [ -z "$PORT_MAIN" ]; then
    PORT_MAIN=8411
fi
read -p "Management port: [8412] " PORT_RAW
if [ -z "$PORT_RAW" ]; then
    PORT_RAW=8412
fi
echo

# local customization
if [ -z "$TMPDIR" ]; then
    TMPDIR=/tmp
fi
PACKAGE=apidoc-`date +%s`
ZIP=${TMPDIR}/${PACKAGE}.zip
echo building $ZIP
mkdir -p "${TMPDIR}/${PACKAGE}"
PACKAGE_LOG=${TMPDIR}/$PACKAGE.log
echo logging to $PACKAGE_LOG
TARGET="${TMPDIR}/${PACKAGE}/"
echo fixing permissions
find "$BASE" -type f -print0 | xargs -0 chmod a+r
find "$BASE" -type d -print0 | xargs -0 chmod a+rx
cp -r "${BASE}/apidoc/package/"* "${TARGET}"
cd "${TMPDIR}/${PACKAGE}"
SERVERS=`echo servers/Default/*.xml`
echo processing $SERVERS
# Set the doc roots. This means BASE must be an absolute path.
sed -e '1,$s:RUNDMC_ROOT:'"${BASE}/src"':g' -i'.bak' $SERVERS
sed -e '1,$s:RUNDMC_PORT_MAIN:'"${PORT_MAIN}"':g' -i'.bak' $SERVERS
sed -e '1,$s:RUNDMC_PORT_RAW:'"${PORT_RAW}"':g' -i'.bak' $SERVERS
# Changing these names? Also change package filename and XML element(name).
mv "servers/Default/rundmc.xml" \
    "servers/Default/${PORT_RAW}-rundmc.xml"
mv "servers/Default/rundmc-apidoc.xml" \
    "servers/Default/${PORT_MAIN}-rundmc-apidoc.xml"
zip -qr "$ZIP" * -x "*.bak"
echo

# use digest not anyauth
CREDENTIAL="--digest -u "${ADMIN_USER}":"${ADMIN_PASSWORD}
URL="http://"${HOSTNAME}":8002/manage/v2"
echo creating package $PACKAGE at $URL
curl --progress-bar \
    -X POST $CREDENTIAL \
    -H "Content-type: application/zip" \
    --data-binary @"$ZIP" \
    "${URL}/packages?pkgname=${PACKAGE}" \
    2>&1 | tee -a "$PACKAGE_LOG"
# error detection
if [ ${PIPESTATUS[0]} != 0 ]; then
    exit 1
fi
grep -q error $PACKAGE_LOG && exit 1 || true
echo

echo installing package $PACKAGE
# Post /dev/null to avoid empty response.
curl --progress-bar \
    -X POST $CREDENTIAL \
    --data-binary @/dev/null \
    -H "Content-type: application/zip" \
    "${URL}/packages/${PACKAGE}/install" \
    2>&1 | tee -a "$PACKAGE_LOG"
# error detection
if [ ${PIPESTATUS[0]} != 0 ]; then
    exit 1
fi
grep -q error $PACKAGE_LOG && exit 1 || true
echo

echo cleaning up
rm "$ZIP"
(cd "${TMPDIR}" && rm -rf "${PACKAGE}")

# download raw docs for processing
cd ${TMPDIR}
ZIP="MarkLogic_7_pubs.zip"
echo $ZIP
[ -r "${ZIP}" ] && unzip -qt "${ZIP}" || rm -f "${ZIP}"
if [ -r "${ZIP}" ]; then
    echo "using existing ${ZIP}"
else
    echo "fetching ${ZIP} from marklogic.com"
    curl --remote-name "http://docs.marklogic.com/${ZIP}" \
    2>&1 | tee -a "$PACKAGE_LOG"
    if [ ${PIPESTATUS[0]} != 0 ]; then
        exit 1
    fi
fi
echo

# process raw docs
VERSION=7.0
URL="http://"${HOSTNAME}":${PORT_RAW}/apidoc/setup/build.xqy"

# doc processing needs schemas for admin help pages
# someday these may be part of the zip
MLCONFIG="/etc/sysconfig/MarkLogic"
if [ -r "${MLCONFIG}" ]; then
    . "${MLCONFIG}"
    XSD="$MARKLOGIC_INSTALL_DIR/Config"
elif [ -d "${HOME}/Library/MarkLogic/Config" ]; then
    # Looks like OSX
    XSD="${HOME}/Library/MarkLogic/Config"
else
    echo no schemas found!
    exit 1
fi
echo using schemas from "${XSD}"

DATA="version=${VERSION}&zip=${TMPDIR}/${ZIP}&help-xsd-dir=${XSD}&clean=1"
echo $DATA
echo Processing... this may take some time.
echo You can watch the ErrorLog.txt for progress.
time curl -D - --max-time 900 -X POST --data "$DATA" $CREDENTIAL "${URL}" \
    2>&1 | tee -a "$PACKAGE_LOG"
if [ ${PIPESTATUS[0]} != 0 ]; then
    exit 1
fi
# error detection
grep -q '500 Internal Server Error' $PACKAGE_LOG && exit 1 || true

echo cleaning up

echo apidoc install ok
echo

# Try to open the new page in a browser
URL="http://"${HOSTNAME}":${PORT_MAIN}"
# The user may have set BROWSER for us.
# If not, this takes care of most linux desktops, plus OSX.
if [ -z "$BROWSER" ]; then
    BROWSER=$(which xdg-open || which gnome-open || which open)
fi
if [ -n "$BROWSER" ]; then
    exec "$BROWSER" "$URL" \
        || echo "Try opening $URL in your favorite browser"
else
    echo "Now open $URL in your favorite browser"
fi

# install-apidoc.sh
