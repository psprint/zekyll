#!/bin/sh

# visual path
VPATH="~/.zekyll/zekyll"
# pre path
PPATH="$HOME/.zekyll"
# actual name
ANAME="zekyll"
# actual path
APATH="$PPATH/$ANAME"

if ! type git 2>/dev/null 1>&2; then
    echo "Please install GIT first"
    echo "Exiting"
    exit 1
fi

if ! test -d "$PPATH"; then
    mkdir "$PPATH"
fi

if test -d "$APATH"; then
    echo ">>> Updating zekyll (found in $VPATH)"
    cd "$APATH"
    git pull origin master
else
    echo ">>> Downloading zekyll to ${VPATH}.."
    cd "$PPATH"
    git clone https://github.com/psprint/zekyll.git "$ANAME"
fi
echo ">>> Done"
