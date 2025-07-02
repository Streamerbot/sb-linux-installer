#!/bin/bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# (c) 2021 FeVR     https://github.com/teamfevr
#          corben78 https://github.com/corben78

function check_distro () {
    # if check has been done before, return immediately
    [ ! -z "$PCKCMD" ] && return 0
    # check distro, arch or debian based
    if [ -f "/etc/os-release" ]; then
        DISTRO=$(grep ^ID_LIKE= /etc/os-release | awk -F '=' '{ print $2 }' | sed 's/^["'\'']//;s/["'\'']$//')
        if [ -z "$DISTRO" ]; then
            DISTRO=$(grep ^ID= /etc/os-release | awk -F '=' '{ print $2 }' | sed 's/^["'\'']//;s/["'\'']$//')
        fi
    fi

    case "$DISTRO" in
        arch)
            PCKCMD="pacman -S"
            ;;
        *ubuntu* | *debian*)
            PCKCMD="apt install"
            ;;
        *)
            unset DISTRO
            ;;
    esac

    if [ -z "$DISTRO" ]; then
        echo unsupported or unknown distribution, exiting
        exit 2
    fi
}

function is_installed () {
    CMD=$1
    if [ -z $(which "$CMD") ]; then
        check_distro
        echo $CMD not found, trying to install
        sudo $PCKCMD $CMD
        if [ "$?" -ne "0" ]; then
            echo failed to install "$CMD". quitting.
            exit 3
        fi
    fi
}

function rmtemp () {
    if [ ! -z "$TMPDIR" ]; then
        rm -r $TMPDIR
    fi
}

LOCAL="$HOME/.local"
SBBIN=$LOCAL/bin
SBDESKTOPPATH="$HOME/.local/share/applications"

# determine installation path
if [ -z $(echo $PATH | grep $HOME/.local/bin) ]; then
    check_distro
    case "$DISTRO" in
    arch)
        if [ -f $HOME/.bash_profile ]; then
            PROFILE=$HOME/.bash_profile
        elif [ -f $HOME/.profile ]; then
            PROFILE=$HOME/.profile
        fi

        if [ ! -z $PROFILE ] && [ -z $(grep .local/bin $PROFILE) ]; then
            [ ! -d $SBBIN ] && mkdir -p $SBBIN
            cat << 'EOF' >> $PROFILE

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
EOF
        else
            echo cannot determine how to add $HOME/.local/bin to $PATH
            exit 9
        fi
        ;;
    *)
        unset $DISTRO
        ;;
    esac
fi

echo install path: $SBBIN

SBPATH=$LOCAL/lib/streamer.bot
SBPFX=$LOCAL/lib/streamer.bot/pfx

if [ ! -z $UNINSTALL ]; then
    [ -d $SBPATH ] && rm -r $SBPATH
    [ -f $SBBIN/streamer.bot ] && rm $SBBIN/streamer.bot
    [ -f $SBDESKTOPPATH/streamerbot.desktop ] && rm $SBDESKTOPPATH/streamerbot.desktop
    echo Streamer.bot removed
    exit 0
fi

if [ -d $SBPATH ] && [ -z $UPDATE ]; then
    echo $SBPATH already exists. quitting.
    exit 5
fi

VERSION="${VERSION:-latest}"

# if not file is given, and no url, grab latest version from SB website API
if [ -z $FILE ]; then
    if [ -z $URL ]; then
        is_installed jq && echo jq is installed
        URL="https://streamer.bot/api/releases/streamer.bot/${VERSION}/download"
    fi

    is_installed wget && echo wget is installed
    TMPDIR=$(mktemp -d)
    cd $TMPDIR
    wget $URL
    if [ "$?" -ne "0" ]; then
        echo download from url $URL failed. exiting.
        exit 4
    fi
    FILE="$TMPDIR"/"$(basename $URL)"
else
    # change to absolute path, just in case a relative path was given
    FILE=$(readlink -f $FILE)
fi

mkdir -p $SBPATH
if [ "$?" -ne "0" ]; then
    echo cannot create $SBPATH. quitting.
    exit 6
fi

cd $SBPATH
unzip -o $FILE
if [ "$?" -ne "0" ]; then
    echo problem extracting $FILE. quitting.
    rmtemp
    exit 7
fi

rmtemp

if [ ! -z $UPDATE ]; then
    echo update finished
    exit 0
fi

# pre-requisites
is_installed wine && echo wine is installed
is_installed winetricks && echo winetricks is installed

WINEPREFIX=$SBPFX wineboot
WINEPREFIX=$SBPFX winetricks -q dotnet48 dxvk d3dcompiler_47 corefonts

# handle failures
if [ "$?" -ne 0 ]; then
    echo winetricks failed. killing remaining processes.
    ps -A | grep -i -e wine -e .exe | awk '{ print $1 }' | sort -r | xargs kill -TERM
    ps -A | grep -i -e wine -e .exe | awk '{ print $1 }' | sort -r | xargs kill -KILL
    exit 8
fi

# create command
cat << EOF > $SBBIN/streamer.bot
#!/bin/bash
cd $SBPATH
DISABLE_MANGOHUD=1 WINEPREFIX=$SBPFX wine Streamer.bot.exe >/dev/null 2>&1
EOF
chmod +x $SBBIN/streamer.bot

#create desktop file
cat << EOF > $SBDESKTOPPATH/streamerbot.desktop
[Desktop Entry]
Name=Streamer.bot
StartupWMClass=streamer.bot.exe
Comment=Bot for Twitch Streamers
GenericName=Chatbot
Exec=env DISABLE_MANGOHUD=1 WINEPREFIX=$SBPFX wine Streamer.bot.exe
Icon=$SBPATH/streamer.bot.png
Type=Application
Categories=Network
Path=$SBPATH
EOF

echo installation successful.

exit 0
