# Streamer.Bot Linux Install Script

With this script you can easily install the latest version of [Streamer.bot](https://github.com/Streamerbot/Streamer.bot) on Linux.
It will create a command `streamer.bot` as well as a menu entry via `streamerbot.desktop`

currently tested distributions:
* Debian/Ubuntu based
* Arch based

If the prerequisites are installed already, this script should work on all distributions

# Usage

* Grab the install.sh script, either directly or via git clone.
* execute `./install.sh`

# Default Settings

## Paths
* `streamer.bot` will be installed below `~/.local/bin`
* uses `~/.local/lib/streamer.bot` for the program files
* uses `~/.local/lib/streamer.bot/pfx` for the wine prefix
* will created a desktop entry via `~/.local/share/applications/streamerbot.desktop`

Make sure `.local/bin` is in your $PATH, e.g. add .local/bin to your $PATH via `.profile` or `.bash_profile` file:
```bash
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
```
This script will try to add these lines if possible.

## Prerequisites

Linux (doh!), with a standard desktop environment, bash, awk, curl, wget, unzip

**mandatory**: `wine`

If not found, `wine` will be installed automatically from the repositories, maybe you want to install it manually before, as Ubuntu, Debian, Fedora will probably have outdated versions.

* Ubuntu: https://wiki.winehq.org/Ubuntu (winehq-staging package recommended)
* Debian: https://wiki.winehq.org/Debian
* Fedora: https://wiki.winehq.org/Fedora

Latest versions in rolling releases available:
* Arch: pacman -S wine
* openSuSE: zypper in wine

**mandatory**: winetricks
https://wiki.winehq.org/Winetricks
https://github.com/Winetricks/winetricks

* Arch: pacman -S winetricks
* openSuSE: zypper in winetricks

# Update

```bash
UPDATE=1 ./install.sh
```

If no other options are given, the script will grab the latest version from github and overwrite the existing files. Can be combined with specifying file location or URL (see below).

# Use local file or specific URL
To fetch a specific version of Streamer.bot:
```bash
VERSION=0.2.0 ./install.sh
```

If you downloaded Streamer.bot already (e.g. a beta), you can specify the `.zip` location:
```bash
FILE=$HOME/Downloads/Streamer.bot-0.1.3-preview4.zip ./install.sh
```

Alternatively you can also provide a specifc url
```bash
URL=https://cdn.discordapp.com/attachments/879546641051422750/881631757550632970/Streamer.bot-0.1.3-preview4.zip ./install.sh
```

# Manual install

If you would like to manually install Streamer.bot:
* create a fresh wine 64-bit prefix
* via winetricks install dotnet48 dxvk and d3dcompiler_47 into that prefix
* Download and install WebView2:
```bash
wget https://github.com/aedancullen/webview2-evergreen-standalone-installer-archive/releases/download/109.0.1518.78/MicrosoftEdgeWebView2RuntimeInstallerX64.exe
WINEPREFIX=<prefix> wine MicrosoftEdgeWebView2RuntimeInstallerX64.exe /silent /install
```
* run Streamer.bot with `WINEPREFIX=<prefix> wine Streamer.bot.exe >/dev/null 2>&1` within the path of the Streamer.bot.exe

# Uninstall

Make a backup first, or save your config. Uninstall will delete Streamer.bot's folder.

```bash
UNINSTALL=1 ./install.sh
```

# Troubleshooting

Winetricks takes a while to complete (several minutes). especially if it has to download from web.archive.org.
winetricks might get stuck, if you interrupt it with ctrl+c the script will try to end all remaining wine processes.
Try to uninstall (see above) and install from scratch again.

# Notes

Big thanks to [nate1280](https://github.com/nate1280/) who relentlessly works on Streamer.bot and adjusted it to work with wine.
