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

if ! test -x "$HOME/$ANAME"; then
    echo
    echo "Creating $ANAME binary in $HOME"
    cp -v "$APATH/zekyll-wrapper" "$HOME/$ANAME"
    chmod +x "$HOME/$ANAME"
    ls -l "$HOME/$ANAME"
    echo ">>> Done"
fi

