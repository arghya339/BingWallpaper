#!/bin/bash

# Copyright (C) 2026, Arghyadeep Mondal <github.com/arghya339>

if [ "$(uname)" == "Darwin" ]; then
  isMacOS=true; isAndroid=false
elif [ -d "/sdcard" ] && [ -d "/system" ]; then
  isAndroid=true; isMacOS=false
fi
BingWallpaper="$HOME/.BingWallpaper"
BingWallpaperJson="$BingWallpaper/BingWallpaper.json"
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
  BingImages="$HOME/Pictures/BingImages"
  displaysResolutionFormat=$(system_profiler SPDisplaysDataType | grep -o "[0-9]* x [0-9]*" | head -1 | tr -d ' ')
  displaysResolutionWidth=$(cut -d'x' -f1 <<< "$displaysResolutionFormat")
  displaysResolutionHeight=$(cut -d'x' -f2 <<< "$displaysResolutionFormat")
fi
Locale=$(jq -r '.Locale' "$BingWallpaperJson" 2>/dev/null)
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
bingJson=$(curl -sL "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=${Locale}")
startdate=$(jq -r '.images[].startdate' <<< "$bingJson")
urlbase=$(jq -r '.images[].urlbase' <<< "$bingJson")
curl -sL -C - ${dohArg[@]} -o $BingImages/$startdate.jpg "https://www.bing.com${urlbase}_${orientationFormat}.jpg&rf=LaDigue_${resolutionFormat}.jpg"
curl -sL -C - ${dohArg[@]} -o "$BingImages/$startdate.json" "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=${Locale}"
SetWallpaperType=$(jq -r '.SetWallpaperType' "$BingWallpaperJson" 2>/dev/null)
SaveBingImages=$(jq -r '.SaveBingImages' "$BingWallpaperJson" 2>/dev/null)
if [ $isAndroid == true ]; then
  if [ "$SetWallpaperType" == "HomeAndLockScreen" ]; then
    termux-wallpaper -f $BingImages/$startdate.jpg
    termux-wallpaper -lf $BingImages/$startdate.jpg
  elif [ "$SetWallpaperType" == "HomeScreen" ]; then
    termux-wallpaper -f $BingImages/$startdate.jpg
  elif [ "$SetWallpaperType" == "LockScreen" ]; then
    termux-wallpaper -lf $BingImages/$startdate.jpg
  fi
  termux-notification --title "BingWallpaper" --content "Wallpaper set successfully!"
elif [ $isMacOS == true ]; then
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"/Users/$USER/Pictures/BingImages/$startdate.jpg\""
  osascript -e 'display notification "Wallpaper set successfully!" with title "BingWallpaper"'
fi
sleep 0.5
[ $SaveBingImages == false ] && rm -f $BingImages/$startdate.jpg $BingImages/$startdate.json