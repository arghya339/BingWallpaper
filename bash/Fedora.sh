#!/bin/bash

# Copyright (C) 2026, Arghyadeep Mondal <github.com/arghya339>

CreateScriptLauncherShortcuts() {
  shortcutLabel=${1}
  scriptPath=${2}
  Interactive=${3:-true}
  [ ! -f "$BingWallpaper/icon_512x512@2x.png" ] && curl -L --progress-bar -C - -o "$BingWallpaper/icon_512x512@2x.png" "https://raw.githubusercontent.com/pengsrc/BingPaper/refs/heads/master/BingPaper/Images.xcassets/AppIcon%20Bing.appiconset/icon_512x512@2x.png"
  cat > "$HOME/.local/share/applications/${shortcutLabel}.desktop" <<EOL
[Desktop Entry]
Name=${shortcutLabel}
Icon=$BingWallpaper/icon_512x512@2x.png
Exec=$scriptPath
Terminal=$Interactive
Type=Application
Categories=Utility;
EOL
}
[ ! -f ~/.local/share/applications/bingwall.desktop ] && CreateScriptLauncherShortcuts "bingwall" "$HOME/.BingWallpaper.sh"
[ ! -f $HOME/.local/share/applications/setwall.desktop ] && CreateScriptLauncherShortcuts "setwall" "$BingWallpaper/SetWallpaper.sh" "false"

[ -f "$BingWallpaperJson" ] && AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$BingWallpaperJson" 2>/dev/null) || AutoUpdatesDependencies=true

dnfUpdate() {
  dnf=${1}
  if grep -q "^$dnf" <<< "$dnfUpgradesList" 2>/dev/null; then
    echo -e "$running Upgrading $dnf package.."
    sudo dnf update "$dnf" -y >/dev/null 2>&1
  fi
}

dnfInstall() {
  dnf=${1}
  if grep -q "^$dnf" <<< "$dnfList" 2>/dev/null; then
    dnfUpdate "$dnf"
  else
    echo -e "$running Installing $dnf package.."
    sudo dnf install "$dnf" -y >/dev/null 2>&1
  fi
}

dnfRemove() {
  dnf=${1}
  dnfList=$(dnf list --installed 2>/dev/null)
  if grep -q "^$dnf" <<< "$dnfList" 2>/dev/null; then
    echo -e "$running Uninstalling $dnf package.."
    sudo dnf remove "$dnf" -y >/dev/null 2>&1
  fi
}

dependencies() {
  dnfList=$(dnf list --installed 2>/dev/null)
  dnfUpgradesList=$(dnf --refresh list --upgrades 2>/dev/null)
  dnfInstall "bash"
  dnfInstall "grep"
  dnfInstall "gawk"
  dnfInstall "sed"
  dnfInstall "curl"
  dnfInstall "jq"
}
[ "$AutoUpdatesDependencies" == true ] && checkInternet && dependencies

SystemLocale=$(cut -d. -f1 <<< $LANG | awk -F'_' '{print $1"-"$2}')
displaysResolutionFormat=$(cat /sys/class/drm/*/modes | head -1)
displaysResolutionWidth=$(cut -d'x' -f1 <<< "$displaysResolutionFormat")
displaysResolutionHeight=$(cut -d'x' -f2 <<< "$displaysResolutionFormat")

systemdTimer() {
  systemctl list-timers --all --no-pager | grep -q "setwall.service" && sudo systemctl stop setwall.service
  sudo tee "/etc/systemd/system/setwall.service" > /dev/null <<EOL
[Unit]
Description=SetWallpaper Task
After=network.target

[Service]
Type=oneshot
EOL
  sudo tee -a "/etc/systemd/system/setwall.service" > /dev/null <<EOL
ExecStart=/usr/bin/bash $BingWallpaper/SetWallpaper.sh
User=$USER
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

[Install]
WantedBy=multi-user.target
EOL
  
  if [ "$Scheduler" != "None" ] || [ "$Timer" != "None" ]; then
    systemctl list-timers --all --no-pager | grep -q "setwall.timer" && sudo systemctl stop setwall.timer
    sudo tee "/etc/systemd/system/setwall.timer" > /dev/null <<EOL
[Unit]
Description=Timer for SetWallpaper

[Timer]
EOL
    [ "$Scheduler" != "None" ] && echo -e "OnActiveSec=5s\nOnUnitActiveSec=$Scheduler" | sudo tee -a "/etc/systemd/system/setwall.timer" > /dev/null
    [ "$Timer" != "None" ] && echo "OnCalendar=*-*-* $Timer:00" | sudo tee -a "/etc/systemd/system/setwall.timer" > /dev/null
    sudo tee -a "/etc/systemd/system/setwall.timer" > /dev/null <<EOL
Persistent=true

[Install]
WantedBy=timers.target
EOL
  fi
  sudo systemctl daemon-reload
  sudo systemctl enable setwall.service
  ([ "$Scheduler" != "None" ] || [ "$Timer" != "None" ]) && sudo systemctl enable --now setwall.timer
  sudo systemctl start setwall.service; sudo systemctl status setwall.service --no-pager
  ([ "$Scheduler" != "None" ] || [ "$Timer" != "None" ]) && { sudo systemctl start setwall.timer; sudo systemctl status setwall.timer --no-pager; }
}