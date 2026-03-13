#!/bin/bash

# Copyright (C) 2026, Arghyadeep Mondal <github.com/arghya339>

CreateAppIcon() {
  responseJson=$(curl -sL "https://api.github.com/repos/pengsrc/BingPaper/contents/BingPaper/Images.xcassets/AppIcon%20Bing.appiconset?ref=master")
  name=($(jq -r '.[].name' <<< "$responseJson"))
  download_url=($(jq -r '.[].download_url' <<< "$responseJson"))
  iconset="$BingWallpaper/Bing.iconset"
  mkdir -p $iconset
  for ((i=0; i<${#name[@]}; i++)); do
    [ "${name[i]}" == "Contents.json" ] && continue
    while true; do
      curl -L --progress-bar -C - -o "$iconset/${name[i]}" "${download_url[i]}" && break || sleep 5
    done
  done
  iconutil -c icns $iconset -o $BingWallpaper/AppIcon.icns && rm -rf $iconset
}
CreateScriptLaunchpadShortcuts() {
  shortcutLabel=${1}
  scriptPath=${2}
  Interactive=${3:-true}
  [ ! -f "$BingWallpaper/AppIcon.icns" ] && CreateAppIcon
  mkdir -p "/Applications/${shortcutLabel}.app/Contents/Resources"
  cp "$BingWallpaper/AppIcon.icns" "/Applications/${shortcutLabel}.app/Contents/Resources/AppIcon.icns"
  mkdir -p "/Applications/${shortcutLabel}.app/Contents/MacOS"
  [ $Interactive == true ] && echo -e "#!/bin/bash\nosascript -e 'tell application \"Terminal\" to do script \"bash ${scriptPath}\"'\nosascript -e 'tell application \"System Events\" to set frontmost of process \"Terminal\" to true'" > "/Applications/${shortcutLabel}.app/Contents/MacOS/launcher" || echo -e "#!/bin/bash\nexport PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"\nsource ${scriptPath}" > "/Applications/${shortcutLabel}.app/Contents/MacOS/launcher"
  chmod +x "/Applications/${shortcutLabel}.app/Contents/MacOS/launcher"
  cat > "/Applications/${shortcutLabel}.app/Contents/Info.plist" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOL
  touch /Applications/${shortcutLabel}.app
  killall Dock
}
[ ! -d "/Applications/bingwall.app/" ] && CreateScriptLaunchpadShortcuts "bingwall" "$HOME/.BingWallpaper.sh"
[ ! -d "/Applications/setwall.app/" ] && CreateScriptLaunchpadShortcuts "setwall" "$BingWallpaper/SetWallpaper.sh" "false"

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

# https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
LaunchAgents() {
  mkdir -p $HOME/Library/LaunchAgents/
  cat > "$HOME/Library/LaunchAgents/com.${USER}.bingwall.plist" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.${USER}.bingwall</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/${USER}/.BingWallpaper/SetWallpaper.sh</string>
    </array>

    <key>KeepAlive</key>
    <dict>
        <key>NetworkState</key>
        <true/>
    </dict>

    <key>RunAtLoad</key>
    <${Boot}/>
EOL
  if [ "$Scheduler" != "None" ]; then
    if [ -z "$SchedulerS" ]; then
      case "$Scheduler" in
        15min) SchedulerS=$((60 * 15)) ;;
        30min) SchedulerS=$((60 * 30)) ;;
        1h) SchedulerS=$((60 * 60)) ;;
        3h) SchedulerS=$((60 * 60 * 3)) ;;
        6h) SchedulerS=$((60 * 60 * 6)) ;;
        9h) SchedulerS=$((60 * 60 * 9)) ;;
        12h) SchedulerS=$((60 * 60 * 12)) ;;
      esac
    fi
    cat >> "$HOME/Library/LaunchAgents/com.${USER}.bingwall.plist" <<EOL

    <key>StartInterval</key>
    <integer>${SchedulerS}</integer>
EOL
  fi
  if [ "$Timer" != "None" ]; then
    HH="${Timer%:*}"
    MM="${Timer#*:}"
    cat >> "$HOME/Library/LaunchAgents/com.${USER}.bingwall.plist" <<EOL

    <key>StartCalendarInterval</key>
    <dict>
        <key>Minute</key>
        <integer>${MM}</integer>
        <key>Hour</key>
        <integer>${HH}</integer>
    </dict>
EOL
  fi
  cat >> "$HOME/Library/LaunchAgents/com.${USER}.bingwall.plist" <<EOL

    <key>StandardOutPath</key>
    <string>/tmp/bingwall.stdout</string>
    <key>StandardErrorPath</key>
    <string>/tmp/bingwall.stderr</string>
</dict>
</plist>
EOL
  launchctl unload $HOME/Library/LaunchAgents/com.${USER}.bingwall.plist
  launchctl load $HOME/Library/LaunchAgents/com.${USER}.bingwall.plist
  launchctl list | grep bingwall
}