#!/bin/bash

BUILD_DIR=`cd ${0%/*} && pwd -P`
ADDON_TMP=$BUILD_DIR/addon_tmp
MODULES_DIR=$ADDON_TMP/redmatic/lib/node_modules

VERSION_ADDON=`jq -r '.version' package.json`
NODE_VERSION=`jq -r '.engines.node' package.json`

MODIFIED=`git diff-index --quiet HEAD || echo "(modified)"`
echo "git diff $MODIFIED"

echo "creating RELEASE_BODY.md"

DOWNLOAD="https://github.com/rdmtc/RedMatic/releases/download/v$VERSION_ADDON/redmatic-$VERSION_ADDON.tar.gz"
DOWNLOAD_I686="https://github.com/rdmtc/RedMatic/releases/download/v$VERSION_ADDON/redmatic-i686-$VERSION_ADDON.tar.gz"
DOWNLOAD_X86_64="https://github.com/rdmtc/RedMatic/releases/download/v$VERSION_ADDON/redmatic-x86_64-$VERSION_ADDON.tar.gz"
DOWNLOAD_ARMV6L="https://github.com/rdmtc/RedMatic/releases/download/v$VERSION_ADDON/redmatic-armv6l-$VERSION_ADDON.tar.gz"
DOWNLOAD_AARCH64="https://github.com/rdmtc/RedMatic/releases/download/v$VERSION_ADDON/redmatic-aarch64-$VERSION_ADDON.tar.gz"

cat >RELEASE_BODY.md <<EOL
### Downloads

#### CCU3, piVCCU3 und RaspberryMatic Varianten _rpi2_, _tinkerboard_ und _oci_arm_ (armv7l)
  [![Downloads redmatic-$VERSION_ADDON](https://img.shields.io/github/downloads/rdmtc/RedMatic/v$VERSION_ADDON/redmatic-$VERSION_ADDON.tar.gz.svg)]($DOWNLOAD)
EOL

if [ -f $BUILD_DIR/dist/redmatic-aarch64-$VERSION_ADDON.tar.gz ]; then
cat >>RELEASE_BODY.md <<EOL
#### RaspberryMatic (>= 3.53.34.20201121) Varianten _rpi3_, _rpi4_ und _oci_arm64_ (aarch64)
  [![Downloads redmatic-aarch64-$VERSION_ADDON](https://img.shields.io/github/downloads/rdmtc/RedMatic/v$VERSION_ADDON/redmatic-aarch64-$VERSION_ADDON.tar.gz.svg)]($DOWNLOAD_AARCH64)
EOL
fi
if [ -f $BUILD_DIR/dist/redmatic-armv6l-$VERSION_ADDON.tar.gz ]; then
cat >>RELEASE_BODY.md <<EOL
#### RaspberryMatic Variante _rpi0_ (armv6l)
  [![Downloads redmatic-armv6l-$VERSION_ADDON](https://img.shields.io/github/downloads/rdmtc/RedMatic/v$VERSION_ADDON/redmatic-armv6l-$VERSION_ADDON.tar.gz.svg)]($DOWNLOAD_ARMV6L)
EOL
fi

if [ -f $BUILD_DIR/dist/redmatic-i686-$VERSION_ADDON.tar.gz ]; then
cat >>RELEASE_BODY.md <<EOL
#### RaspberryMatic Varianten _ova_ und _intelnuc_ (i686)
  [![Downloads redmatic-i686-$VERSION_ADDON](https://img.shields.io/github/downloads/rdmtc/RedMatic/v$VERSION_ADDON/redmatic-i686-$VERSION_ADDON.tar.gz.svg)]($DOWNLOAD_I686)
EOL
fi

if [ -f $BUILD_DIR/dist/redmatic-x86_64-$VERSION_ADDON.tar.gz ]; then
cat >>RELEASE_BODY.md <<EOL
#### RaspberryMatic (>= 3.53.34.20201121) Varianten _ova_, _intelnuc_ und _oci_amd64_ (x86_64)
  [![Downloads redmatic-x86_64-$VERSION_ADDON](https://img.shields.io/github/downloads/rdmtc/RedMatic/v$VERSION_ADDON/redmatic-x86_64-$VERSION_ADDON.tar.gz.svg)]($DOWNLOAD_X86_64)
EOL
fi

cat >>RELEASE_BODY.md <<EOL


### Changes

EOL

git log `git describe --tags --abbrev=0`..HEAD --pretty=format:'* %h @%an %s' \
    | grep -v "Merge remote-tracking branch" \
    | grep -vi "update readme" \
    | grep -vi "bump version" \
    | sed -e 's/Sebastian Raff/hobbyquaker/g' \
    >>RELEASE_BODY.md

cat >>RELEASE_BODY.md <<EOL


**[Change History](https://github.com/rdmtc/RedMatic/wiki/CHANGE_HISTORY)**


### Module Versions

Module | Version
------ | -------
[Node.js](https://nodejs.org/de/) | $NODE_VERSION
EOL

scan_dir()
{
    for DIR in $1/*
    do
        if [[ -f $DIR/package.json ]]; then
            PKG=$(jq -r '.name' $DIR/package.json)
            VERSION=$(jq -r '.version' $DIR/package.json)
            HOMEPAGE=$(jq -r '.homepage' $DIR/package.json)

            if [ $HOMEPAGE != null ]; then
                echo "[$PKG]($HOMEPAGE) | $VERSION" >> RELEASE_BODY.md
            else
                echo "$PKG | $VERSION" >> RELEASE_BODY.md
            fi
        fi
        case ${DIR##*/} in @*)
            scan_dir "$DIR"
        esac
    done
}

scan_dir $MODULES_DIR
scan_dir $ADDON_TMP/redmatic/var/node_modules

cat >>RELEASE_BODY.md <<EOL


### Build
EOL

if [ $TRAVIS_BUILD_ID ]; then
    echo -e "[Travis Build #$TRAVIS_BUILD_NUMBER](https://travis-ci.org/rdmtc/RedMatic/builds/$TRAVIS_BUILD_ID)" >> RELEASE_BODY.md
elif [ $GITHUB_RUN_ID ]; then
    echo -e "[Github Action $GITHUB_WORKFLOW #$GITHUB_RUN_NUMBER](https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)" >> RELEASE_BODY.md
else
    echo -e "\n\nCustom build `git rev-parse --abbrev-ref HEAD` `git rev-parse HEAD` $MODIFIED `date '+%Y-%m-%d %H:%M:%S'`" >> RELEASE_BODY.md
fi
