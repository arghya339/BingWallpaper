#!/bin/bash

# Copyright (C) 2026, Arghyadeep Mondal <github.com/arghya339>

ping -c 1 -W 2 8.8.8.8 &>/dev/null || exit 1
if [ "$(uname)" == "Darwin" ]; then
  isMacOS=true; isAndroid=false; isFedora=false
elif [ -d "/sdcard" ] && [ -d "/system" ]; then
  isAndroid=true; isMacOS=false; isFedora=false
elif [ -f "/etc/os-release" ]; then
  if grep -qi "fedora" /etc/os-release 2>/dev/null; then
    isFedora=true; isAndroid=false; isMacOS=false
  fi
fi
BingWallpaper="$HOME/.BingWallpaper"
BingWallpaperJson="$BingWallpaper/BingWallpaper.json"
BingImages="$HOME/Pictures/BingImages"
if [ $isAndroid == true ]; then
  SystemLocale=$(getprop ro.product.locale)
  BingImages="/sdcard/Pictures/BingImages"
  su -c "id" >/dev/null 2>&1 && su=true || su=false
  runCmd() {
    cmd=${1}
    if [ $su == true ]; then
      su -c "$cmd"
    elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
      ~/rish -c "$cmd"
    elif "$HOME/adb" -s $(~/adb devices | grep "device$" | awk '{print $1}' | tail -1) shell "id" >/dev/null 2>&1; then
      ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "$cmd"
    fi
  }
  displaysResolutionFormat=$(grep "Physical size" <<< "$runCmdOut" | cut -d' ' -f3); unset runCmdOut
  [ -z "$displaysResolutionFormat" ] && displaysResolutionFormat="1080x1920"
  displaysResolutionWidth=${displaysResolutionFormat%x*}
  displaysResolutionHeight=${displaysResolutionFormat#*x}
elif [ $isMacOS == true ]; then
  SystemLocale=$(defaults read -g AppleLocale | cut -d'@' -f1 | awk -F'_' '{print $1"-"$2}')
  displaysResolutionFormat=$(system_profiler SPDisplaysDataType | grep -o "[0-9]* x [0-9]*" | head -1 | tr -d ' ')
  displaysResolutionWidth=$(cut -d'x' -f1 <<< "$displaysResolutionFormat")
  displaysResolutionHeight=$(cut -d'x' -f2 <<< "$displaysResolutionFormat")
else
  SystemLocale=$(cut -d. -f1 <<< $LANG | awk -F'_' '{print $1"-"$2}')
  displaysResolutionFormat=$(cat /sys/class/drm/*/modes | head -1)
  displaysResolutionWidth=$(cut -d'x' -f1 <<< "$displaysResolutionFormat")
  displaysResolutionHeight=$(cut -d'x' -f2 <<< "$displaysResolutionFormat")
fi
Locale=$(jq -r '.Locale' "$BingWallpaperJson" 2>/dev/null)
[ "$Locale" == "Auto" ] && Locale="$SystemLocale"
DoH=$(jq -r '.DoH' "$BingWallpaperJson" 2>/dev/null)
[ -n "$DoH" ] && dohArg=("--doh-url" "$DoH") || dohArg=()
mkdir -p $BingImages
Resolution=$(jq -r '.Resolution' "$BingWallpaperJson" 2>/dev/null)
[ $displaysResolutionWidth -lt $displaysResolutionHeight ] && isOrientation="Portrait" || isOrientation="Landscape"
case "$Resolution" in
  Auto) resolutionFormat="$displaysResolutionFormat" ;;
  UHD) resolutionFormat="UHD" ;;
  QHD) [ "$isOrientation" == "Portrait" ] && resolutionFormat="1440x2560" || resolutionFormat="2560x1440" ;;
  FHD) [ "$isOrientation" == "Portrait" ] && resolutionFormat="1080x1920" || resolutionFormat="1920x1080" ;;
  HD) [ "$isOrientation" == "Portrait" ] && resolutionFormat="720x1280" || resolutionFormat="1280x720" ;;
  SD) [ "$isOrientation" == "Portrait" ] && resolutionFormat="480x800" || resolutionFormat="800x480" ;;
esac
Orientation=$(jq -r '.Orientation' "$BingWallpaperJson" 2>/dev/null)
[ "$Orientation" == "Portrait" ] && orientationFormat="1080x1920" || orientationFormat="1920x1080"
SetWallpaperType=$(jq -r '.SetWallpaperType' "$BingWallpaperJson" 2>/dev/null)
SaveBingImages=$(jq -r '.SaveBingImages' "$BingWallpaperJson" 2>/dev/null)
Wallpaper=$(jq -r '.Wallpaper' "$BingWallpaperJson" 2>/dev/null)
bingJson=$(curl -sL "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=${Locale}")
startdate=$(jq -r '.images[].startdate' <<< "$bingJson")
fileName="$startdate.jpg"
filePath="$BingImages/$fileName"
urlbase=$(jq -r '.images[].urlbase' <<< "$bingJson")
images_url="https://www.bing.com${urlbase}_${orientationFormat}.jpg&rf=LaDigue_${resolutionFormat}.jpg"
if [ "$Wallpaper" != "$fileName" ]; then
  [ $SaveBingImages == true ] && curl -sL -C - ${dohArg[@]} -o "$BingImages/$startdate.json" "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=${Locale}"
  curl -sL -C - ${dohArg[@]} -o $filePath $images_url
  if [ $isAndroid == true ]; then
    if [ "$SetWallpaperType" == "HomeAndLockScreen" ]; then
      termux-wallpaper -f $filePath
      termux-wallpaper -lf $filePath
    elif [ "$SetWallpaperType" == "HomeScreen" ]; then
      termux-wallpaper -f $filePath
    elif [ "$SetWallpaperType" == "LockScreen" ]; then
      termux-wallpaper -lf $filePath
    fi
    termux-notification --title "BingWallpaper" --content "Wallpaper set successfully!"
  elif [ $isMacOS == true ]; then
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"/Users/$USER/Pictures/BingImages/$fileName\""
    osascript -e 'display notification "Wallpaper set successfully!" with title "BingWallpaper"'
  elif [ $isFedora == true ]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$filePath"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$filePath"
    notify-send "BingWallpaper" "Wallpaper set successfully!"
  fi
  if [ $SaveBingImages == false ]; then
    [ $isAndroid == true ] && rm -f $filePath || rm -f $BingImages/$Wallpaper
  fi
  jq --arg key "Wallpaper" --arg value "$fileName" '.[$key] = $value' "$BingWallpaperJson" > $BingWallpaper/temp.json && mv $BingWallpaper/temp.json "$BingWallpaperJson"
fi
