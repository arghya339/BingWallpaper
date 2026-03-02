#!/bin/bash

# Copyright (C) 2026, Arghyadeep Mondal <github.com/arghya339>

[ -f "$BingWallpaperJson" ] && AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$BingWallpaperJson" 2>/dev/null) || AutoUpdatesDependencies=true

formulaeUpdate() {
  formulae=$1
  if echo "$outdatedFormulae" | grep -q "^$formulae" 2>/dev/null; then
    echo -e "$running Upgrading $formulae formulae.."
    brew upgrade "$formulae" > /dev/null 2>&1
  fi
}

formulaeInstall() {
  formulae=$1
  if echo "$formulaeList" | grep -q "$formulae" 2>/dev/null; then
    formulaeUpdate "$formulae"
  else
    echo -e "$running Installing $formulae formulae.."
    brew install "$formulae" > /dev/null 2>&1
  fi
}

formulaeUninstall() {
  formulaeList=$(brew list 2>/dev/null)
  formulae=$1
  if echo "$formulaeList" | grep -q "$formulae" 2>/dev/null; then
    echo -e "$running Uninstalling $formulae formulae.."
    brew uninstall "$formulae" > /dev/null 2>&1
  fi
}

dependencies() {
  formulaeList=$(brew list 2>/dev/null)
  outdatedFormulae=$(brew outdated 2>/dev/null)
  
  brew --version >/dev/null 2>&1 && brew update > /dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  formulaeInstall "bash"
  formulaeInstall "grep"
  formulaeInstall "curl"
  formulaeInstall "jq"
}
[ "$AutoUpdatesDependencies" == true ] && checkInternet && dependencies

SystemLocale=$(defaults read -g AppleLocale | cut -d'@' -f1 | awk -F'_' '{print $1"-"$2}')
displaysResolutionFormat=$(system_profiler SPDisplaysDataType | grep -o "[0-9]* x [0-9]*" | head -1 | tr -d ' ')
displaysResolutionWidth=$(cut -d'x' -f1 <<< "$displaysResolutionFormat")
displaysResolutionHeight=$(cut -d'x' -f2 <<< "$displaysResolutionFormat")
