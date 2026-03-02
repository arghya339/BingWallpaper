#!/usr/bin/env bash

# Copyright (C) 2026, Arghyadeep Mondal <github.com/arghya339>

shopt -s extglob

good="\033[92;1m[✔]\033[0m"
bad="\033[91;1m[✘]\033[0m"
info="\033[94;1m[i]\033[0m"
running="\033[37;1m[~]\033[0m"
notice="\033[93;1m[!]\033[0m"
buttonsSymbol="➤"

Green="\033[92m"
Red="\033[91m"
whiteBG="\e[47m\e[30m"
Yellow="\033[93m"
Reset="\033[0m"

checkInternet() {
  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    return
  else
    echo -e "$bad ${Red}No Internet Connection available!${Reset}"
    return 1
  fi
}

if [[ "$(uname)" == "Darwin" ]]; then
  isMacOS=true; isAndroid=false
elif [[ -d "/sdcard" ]] && [[ -d "/system" ]]; then
  isAndroid=true; isMacOS=false
fi

BingWallpaper="$HOME/.BingWallpaper"
BingWallpaperJson="$BingWallpaper/BingWallpaper.json"
[ $isAndroid == true ] && BingImages="/sdcard/Pictures/BingImages" || BingImages="$HOME/Pictures/BingImages"
mkdir -p $BingWallpaper $BingImages
read rows cols < <(stty size)
eButtons=("<Select>" "<Exit>")
bButtons=("<Select>" "<Back>")
ynButtons=("<Yes>" "<No>")
tfButtons=("<true>" "<false>")

[ $isAndroid == true ] && scripts=(Termux)
[ $isMacOS == true ] && scripts=(macOS)
scripts+=(menu confirmPrompt)

run() {
  [ $isAndroid == true ] && source $BingWallpaper/apkInstall.sh
  for ((c=0; c<${#scripts[@]}; c++)); do
    script="${scripts[c]}"
    source $BingWallpaper/$script.sh
  done
}

[ -f "$BingWallpaper/.version" ] && localVersion=$(cat "$BingWallpaper/.version") || localVersion=
checkInternet &>/dev/null && remoteVersion=$(curl -sL "https://raw.githubusercontent.com/arghya339/BingWallpaper/refs/heads/main/bash/.version") || remoteVersion="$localVersion"
updates() {
  curl -sL -o "$BingWallpaper/.version" "https://raw.githubusercontent.com/arghya339/BingWallpaper/refs/heads/main/bash/.version"
  curl -sL -o "$HOME/.BingWallpaper.sh" "https://raw.githubusercontent.com/arghya339/BingWallpaper/refs/heads/main/bash/BingWallpaper.sh"
  curl -sL -o "$BingWallpaper/SetWallpaper.sh" "https://raw.githubusercontent.com/arghya339/BingWallpaper/refs/heads/main/bash/SetWallpaper.sh"
  if [ $isAndroid == true ]; then
    [ ! -f "$PREFIX/bin/bingwall" ] && ln -s ~/.BingWallpaper.sh $PREFIX/bin/bingwall
    [ ! -f "$PREFIX/bin/setwall" ] && ln -s $BingWallpaper/SetWallpaper.sh $PREFIX/bin/setwall
  elif [ $isMacOS == true ]; then
    [ ! -f "/usr/local/bin/bingwall" ] && ln -s $HOME/.BingWallpaper.sh /usr/local/bin/bingwall
    [ ! -f "/usr/local/bin/setwall" ] && ln -s $BingWallpaper/SetWallpaper.sh /usr/local/bin/setwall
  fi
  [ ! -x $HOME/.BingWallpaper.sh ] && chmod +x $HOME/.BingWallpaper.sh
  [ ! -x $BingWallpaper/SetWallpaper.sh ] && chmod +x $BingWallpaper/SetWallpaper.sh
  if [ $isAndroid == true ]; then
    curl -sL -o "$BingWallpaper/apkInstall.sh" "https://raw.githubusercontent.com/arghya339/Simplify/refs/heads/main/Termux/apkInstall.sh"
    source $BingWallpaper/apkInstall.sh
  fi
  curl -sL -o $BingWallpaper/menu.sh https://raw.githubusercontent.com/arghya339/Simplify/refs/heads/next/bash/menu.sh
  curl -sL -o $BingWallpaper/confirmPrompt.sh https://raw.githubusercontent.com/arghya339/Simplify/refs/heads/next/bash/confirmPrompt.sh
  curl -sL -o "$BingWallpaper/${scripts[0]}.sh" "https://raw.githubusercontent.com/arghya339/BingWallpaper/refs/heads/main/bash/${scripts[0]}.sh"
  for ((c=0; c<${#scripts[@]}; c++)); do
    script="${scripts[c]}"
    source $BingWallpaper/$script.sh
  done
}
[ -f "$BingWallpaperJson" ] && AutoUpdatesScript=$(jq -r '.AutoUpdatesScript' "$BingWallpaperJson" 2>/dev/null) || AutoUpdatesScript=true
if [ "$AutoUpdatesScript" == true ]; then
  [ "$remoteVersion" != "$localVersion" ] && { checkInternet && updates && localVersion="$remoteVersion"; } || run
else
  run
fi

if [[ ($displaysResolutionWidth -ge 3840 && $displaysResolutionHeight -ge 2160) || ($displaysResolutionWidth -ge 2160 && $displaysResolutionHeight -ge 3840) ]]; then
  Quality=UHD
elif [[ ($displaysResolutionWidth -ge 2560 && $displaysResolutionHeight -ge 1440) || ($displaysResolutionWidth -ge 1440 && $displaysResolutionHeight -ge 2560) ]]; then
  Quality=QHD
elif [[ ($displaysResolutionWidth -ge 1920 && $displaysResolutionHeight -ge 1080) || ($displaysResolutionWidth -ge 1080 && $displaysResolutionHeight -ge 1920) ]]; then
  Quality=FHD
elif [[ ($displaysResolutionWidth -ge 1280 && $displaysResolutionHeight -ge 720) || ($displaysResolutionWidth -ge 720 && $displaysResolutionHeight -ge 1280) ]]; then
  Quality=HD
else
  Quality=SD
fi

config() {
  key="$1"
  value="$2"
  
  [ ! -f "$BingWallpaperJson" ] && jq -n "{}" > "$BingWallpaperJson"
  jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$BingWallpaperJson" > temp.json && mv temp.json "$BingWallpaperJson"
}

[ $displaysResolutionWidth -lt $displaysResolutionHeight ] && isOrientation="Portrait" || isOrientation="Landscape"

all_key=(AutoUpdatesScript AutoUpdatesDependencies Orientation Resolution SaveBingImages Locale DoH)
all_value=(true true "$isOrientation" Auto false Auto "")
[ $isAndroid == true ] && { all_key+=(AutoUpdatesTermux SetWallpaperType); all_value+=(true HomeAndLockScreen); }
for i in "${!all_key[@]}"; do
  ! jq -e --arg key "${all_key[i]}" 'has($key)' "$BingWallpaperJson" &>/dev/null && config "${all_key[i]}" "${all_value[i]}"
done

reloadConfig() {
  if [ -f "$BingWallpaperJson" ]; then
    AutoUpdatesScript=$(jq -r '.AutoUpdatesScript' "$BingWallpaperJson" 2>/dev/null)
    AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$BingWallpaperJson" 2>/dev/null)
    AutoUpdatesTermux=$(jq -r '.AutoUpdatesTermux' "$BingWallpaperJson" 2>/dev/null)
    Orientation=$(jq -r '.Orientation' "$BingWallpaperJson" 2>/dev/null)
    Resolution=$(jq -r '.Resolution' "$BingWallpaperJson" 2>/dev/null)
    SetWallpaperType=$(jq -r '.SetWallpaperType' "$BingWallpaperJson" 2>/dev/null)
    SaveBingImages=$(jq -r '.SaveBingImages' "$BingWallpaperJson" 2>/dev/null)
    Locale=$(jq -r '.Locale' "$BingWallpaperJson" 2>/dev/null)
    DoH=$(jq -r '.DoH' "$BingWallpaperJson" 2>/dev/null)
  else
    AutoUpdatesScript=true
    AutoUpdatesDependencies=true
    AutoUpdatesTermux=true
    Orientation="$isOrientation"
    Resolution=Auto
    SetWallpaperType="HomeAndLockScreen"
    SaveBingImages=false
    Locale=Auto
    DoH=ISP
  fi
  case "$Resolution" in
    Auto) resolutionFormat="$displaysResolutionFormat" ;;
    UHD) resolutionFormat="UHD" ;;
    QHD) [ "$isOrientation" == "Portrait" ] && resolutionFormat="1440x2560" || resolutionFormat="2560x1440" ;;
    FHD) [ "$isOrientation" == "Portrait" ] && resolutionFormat="1080x1920" || resolutionFormat="1920x1080" ;;
    HD) [ "$isOrientation" == "Portrait" ] && resolutionFormat="720x1280" || resolutionFormat="1280x720" ;;
    SD) [ "$isOrientation" == "Portrait" ] && resolutionFormat="480x800" || resolutionFormat="800x480" ;;
  esac
  [ "$Orientation" == "Portrait" ] && orientationFormat="1080x1920" || orientationFormat="1920x1080"
  [ "$Locale" == "Auto" ] && Locale="$SystemLocale"
  [ -n "$DoH" ] && dohArg=("--doh-url" "$DoH") || dohArg=()
}; reloadConfig

while true; do
  options=(Official Third-party Browse Settings)
  descriptions=("https://www.bing.com/" "https://bing.npanuhin.me/" "BrowseBingImages" "BingWallpaperSettings")
  menu options eButtons descriptions
  case "${options[selected]}" in
    Official)
      bingJson=$(curl -sL "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=7&mkt=${Locale}")
      mapfile -t startdates < <(jq -r '.images[].startdate' <<< "$bingJson")
      mapfile -t urlbases < <(jq -r '.images[].urlbase' <<< "$bingJson")
      mapfile -t descriptions < <(jq -r '.images[].copyright' <<< "$bingJson" | awk -F' \\(' '{print $1}')
      #mapfile -t copyrights < <(jq -r '.images[].copyright' <<< "$bingJson" | awk -F' \\(' '{print $2}' | tr -d ')')
      mapfile -t titles < <(jq -r '.images[].title' <<< "$bingJson")
      if [ "$Locale" == "zh-CN" ]; then
        translated_titles=(); translated_descriptions=()
        for ((i=0; i<${#startdates[@]}; i++)); do
          text_arrays=("${titles[i]}" "${descriptions[i]}")
          for ((j=0; j<${#text_arrays[@]}; j++)); do
            encoded_text=$(jq -rn --arg text "${text_arrays[j]}" '$text|@uri')
            translated_text=$(curl -sL "https://mozhi.aryak.me/api/translate?engine=google&from=zh-CN&to=en&text=${encoded_text}" | jq -r '."translated-text"')
            [ $j -eq 0 ] && translated_titles+=("$translated_text") || translated_descriptions+=("$translated_text")
          done
        done
        titles=("${translated_titles[@]}")
        descriptions=("${translated_descriptions[@]}")
      fi
      selected=0
      while true; do
        if menu titles bButtons descriptions startdates $selected; then
          urlbase=${urlbases[selected]}
          startdate=${startdates[selected]}
          curl -sL -C - ${dohArg[@]} -o $BingImages/$startdate.jpg "https://www.bing.com${urlbase}_${orientationFormat}.jpg&rf=LaDigue_${resolutionFormat}.jpg"
          curl -sL -C - ${dohArg[@]} -o "$BingImages/$startdate.json" "https://www.bing.com/HPImageArchive.aspx?format=js&idx=${selected}&n=1&mkt=${Locale}"
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
            #osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$BingImages/$startdate.jpg\""
            osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"/Users/$(whoami)/Pictures/BingImages/$startdate.jpg\""
            osascript -e 'display notification "Wallpaper set successfully!" with title "BingWallpaper"'
          fi
          sleep 0.5
          [ $SaveBingImages == false ] && rm -f $BingImages/$startdate.jpg $BingImages/$startdate.json
        else
          break
        fi
      done
      ;;
    Third-party)
      #availableLocale=($(curl -sL https://bing.npanuhin.me/all.json | jq -r 'keys[]'))
      availableLocale=(BR-pt CA-en CA-fr CN-zh DE-de ES-es FR-fr GB-en IN-en IT-it JP-ja ROW-en US-en)
      countryLang=$(awk -F'-' '{print $2"-"$1}' <<< "$Locale")
      grep -q "$countryLang" <<< "${availableLocale[@]}" &>/dev/null || countryLang="ROW-en"
      responseJson=$(curl -sL https://bing.npanuhin.me/${countryLang}.json | jq -r 'reverse')
      dates=($(jq -r '.[].date' <<< "$responseJson"))
      bing_urls=($(jq -r '.[].bing_url' <<< "$responseJson"))
      mapfile -t titles < <(jq -r '.[].title' <<< "$responseJson")
      selected=0
      while true; do
        if menu dates bButtons titles "" $selected; then
          date=${dates[selected]}
          bing_url=$(sed "s/UHD/${orientationFormat}.jpg\&rf=LaDigue_${esolutionFormat}/" <<< "${bing_urls[selected]}")
          curl -sL -C - ${dohArg[@]} -o $BingImages/$date.jpg $bing_url
          if [ $isAndroid == true ]; then
            if [ "$SetWallpaperType" == "HomeAndLockScreen" ]; then
              termux-wallpaper -f $BingImages/$date.jpg
              termux-wallpaper -lf $BingImages/$date.jpg
            elif [ "$SetWallpaperType" == "HomeScreen" ]; then
              termux-wallpaper -f $BingImages/$date.jpg
            elif [ "$SetWallpaperType" == "LockScreen" ]; then
              termux-wallpaper -lf $BingImages/$date.jpg
            fi
            termux-notification --title "BingWallpaper" --content "Wallpaper set successfully!"
          elif [ $isMacOS == true ]; then
            osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"/Users/$(whoami)/Pictures/BingImages/$date.jpg\""
            osascript -e 'display notification "Wallpaper set successfully!" with title "BingWallpaper"'
          fi
          sleep 0.5
          [ $SaveBingImages == false ] && rm -f $BingImages/$date.jpg
        else
          break
        fi
      done
      ;;
    Browse)
      contentsJson=$(curl -sL "https://api.github.com/repos/niumoo/bing-wallpaper/contents/picture?ref=main" | jq -r 'reverse')
      names=($(jq -r '.[].name' <<< "$contentsJson"))
      html_urls=($(jq -r '.[].html_url' <<< "$contentsJson"))
      selected=0
      while true; do
        if menu names bButtons html_urls "" $selected; then
          [ $isAndroid == true ] && termux-open "${html_urls[selected]}/README.md" || open "${html_urls[selected]}/README.md"
        else
          break
        fi
      done
      ;;
    Settings)
      while true; do
        sOptions=(AutoUpdatesScript AutoUpdatesDependencies CheckUpdates Version Orientation BingImagesQuality SaveBingImages Country DoH Uninstall SourceCode)
        sDescriptions=(AutoUpdatesScriptOnLaunch AutoUpdatesDependenciesOnLaunch ManuallyUpdatingScript ScriptVersion ScreenOrientation Resolution SaveWallpaper2Photos Locale DNSoverHTTPS UninstallScript github.com/arghya339/BingWallpaper)
        [ $isAndroid == true ] && { sOptions+=(AutoUpdatesTermux SetWallpaperType Share); sDescriptions+=(AutoUpdatesTermuxOnLaunch SetWallpaperType ShareScript); }
        [ $isMacOS == true ] && { sOptions+=(RestartDock); sDescriptions+=(RestartMacOSDock); }
        if menu sOptions bButtons sDescriptions; then
          case "${sOptions[selected]}" in
            AutoUpdatesScript)
              confirmPrompt "Auto updates Script on launch" tfButtons "$AutoUpdatesScript" && autoupdates=true || autoupdates=false
              config "AutoUpdatesScript" "$autoupdates"
              reloadConfig
              echo; read -p "Press Enter to continue..."
              ;;
            AutoUpdatesDependencies)
              confirmPrompt "Auto updates dependencies on launch" tfButtons "$AutoUpdatesDependencies" && autoupdates=true || autoupdates=false
              config "AutoUpdatesDependencies" "$autoupdates"
              reloadConfig
              echo; read -p "Press Enter to continue..."
              ;;
            CheckUpdates) checkInternet && { updates; dependencies; } ;;
            Version)
              echo $localVersion
              echo; read -p "Press Enter to continue..."
              ;;
            AutoUpdatesTermux)
              confirmPrompt "Auto updates Termux on launch" tfButtons "$AutoUpdatesTermux" && AutoUpdatesTermux=true || AutoUpdatesTermux=false
              config "AutoUpdatesTermux" "$AutoUpdatesTermux"
              reloadConfig
              echo; read -p "Press Enter to continue..."
              ;;
            Orientation)
              [ "$Orientation" == "Portrait" ] && selected_buttons=0 || selected_buttons=1
              Buttons=("<Portrait>" "<Landscape>"); confirmPrompt "Screen Orientation" Buttons "$selected_buttons" && Orientation=Portrait || Orientation=Landscape
              config "Orientation" "$Orientation"; reloadConfig
              ;;
            BingImagesQuality)
              qOptions=("Auto($Quality)" UHD QHD FHD HD SD)
              qDescriptions=(LetTheScriptDecideBasedOnSystemResources 4k 2k 1080p 720p 480p)
              if menu qOptions bButtons qDescriptions; then
                case "${qOptions[selected]}" in
                  Auto*) config "Resolution" "Auto" && reloadConfig ;;
                  *) config "Resolution" "${qOptions[selected]}" && reloadConfig ;;
                esac
              fi
              ;;
            SetWallpaperType)
              case "$SetWallpaperType" in
                HomeAndLockScreen) selected_options=0 ;;
                HomeScreen) selected_options=1 ;;
                LockScreen) selected_options=2 ;;
              esac
              options=(HomeAndLockScreen HomeScreen LockScreen)
              descriptions=(SetWallpaperOnBothHomeAndLockScreen SetWallpaperOnlyHomeScreen SetWallpaperOnlyLockScreen)
              if menu options bButtons descriptions "" $selected_options; then
                config "SetWallpaperType" "${options[selected]}"
                reloadConfig
              fi
              ;;
            SaveBingImages)
              confirmPrompt "SaveBingImages" tfButtons "$SaveBingImages" && SaveBingImages=true || SaveBingImages=false
              config "SaveBingImages" "$SaveBingImages"
              reloadConfig
              echo; read -p "Press Enter to continue..."
              ;;
            Country)
              Country=$(jq -r '.Locale' "$BingWallpaperJson" 2>/dev/null)
              case "$Country" in
                Auto) selected_options=0 ;;
                "en-ROW") selected_options=1 ;;
                "pt-BR") selected_options=2 ;;
                "bg-BG") selected_options=3 ;;
                "en-CA") selected_options=4 ;;
                "zh-CN") selected_options=5 ;;
                "fr-FR") selected_options=6 ;;
                "de-DE") selected_options=7 ;;
                "en-IN") selected_options=8 ;;
                "fa-IR") selected_options=9 ;;
                "it-IT") selected_options=10 ;;
                "ja-JP") selected_options=11 ;;
                "es-ES") selected_options=12 ;;
                "en-GB") selected_options=13 ;;
                "en-US") selected_options=14 ;;
              esac
              cOptions=("Auto($SystemLocale)" International Brazil Bulgaria Canada China France Germany India Iran Italy Japan Spain UnitedKingdom UnitedStates)
              cDescriptions=(LetTheScriptDecideBasedOnSystemLocale en-ROW pt-BR bg-BG en-CA zh-CN fr-FR de-DE en-IN fa-IR it-IT ja-JP es-ES en-GB en-US)
              if menu cOptions bButtons cDescriptions "" $selected_options; then
                case "${cOptions[selected]}" in
                  Auto*) config "Locale" "Auto" ;;
                  *) config "Locale" "${cDescriptions[selected]}" ;;
                esac
                reloadConfig
              fi
              ;;
            DoH)
              dOptions=(ISP Google Cloudflare OpenDNS AdGuard CleanBrowsing quad9 Custom)
              dDescriptions=("InternetServiceProvider'sDomainNameServers" "https://dns.google/dns-query" "https://cloudflare-dns.com/dns-query" "https://dns.opendns.com/dns-query" "https://dns.adguard-dns.com/dns-query" "https://doh.cleanbrowsing.org/doh/security-filter" "https://dns.quad9.net/dns-query" "UserDefined")
              if menu dOptions bButtons dDescriptions; then
                case "${dOptions[selected]}" in
                  ISP) DoH="" ;;
                  Google) DoH="https://dns.google/dns-query" ;;
                  Cloudflare) DoH="https://cloudflare-dns.com/dns-query" ;;
                  OpenDNS) DoH="https://dns.opendns.com/dns-query" ;;
                  AdGuard) DoH="https://dns.adguard-dns.com/dns-query" ;;
                  CleanBrowsing) DoH="https://doh.cleanbrowsing.org/doh/security-filter" ;;
                  quad9) DoH="https://dns.quad9.net/dns-query" ;;
                  Custom) read -r -p "DoH: " -i "https://dns.google/dns-query" -e DoH ;;
                esac
                config "DoH" "$DoH"
                reloadConfig
              fi
              ;;
            RestartDock) killall Dock ;;
            Uninstall)
              confirmPrompt "Are you sure you want to uninstall BingWallpaper?" "ynButtons" "1" && response=Yes || response=No
              case "$response" in
                Yes)
                  echo -ne "${Red}Type 'yes' in capital to continue: ${Reset}" && read -r userInput
                  case "$userInput" in
                    YES)
                      [ -d "$BingWallpaper" ] && rm -rf "$BingWallpaper"
                      [ -f "$HOME/.BingWallpaper.sh" ] && rm -f "$HOME/.BingWallpaper.sh"
                      [ -f "/usr/local/bin/bingwall" ] && rm -f "/usr/local/bin/bingwall"
                      confirmPrompt "Do you want to remove this script-related dependency?" "ynButtons" "1" && response=Yes || response=No
                      case "$response" in
                        Yes) [ $isAndroid == true ] && { pkgUninstall "jq"; pkgUninstall "termux-api"; } || formulaeUninstall "jq" ;;
                      esac
                      confirmPrompt "Do you want to remove Saved BingImages from Photos?" "ynButtons" "1" && response=Yes || response=No
                      case "$response" in
                        Yes) [ -d "$BingImages" ] && rm -rf "$BingImages" ;;
                      esac
                      printf '\033[2J\033[3J\033[H'
                      echo -e "$good ${Yellow}BingWallpaper has been uninstalled successfully :(${Reset}"
                      echo -e "💔 ${Yellow}We're sorry to see you go. Feel free to reinstall anytime!${Reset}"
                      [ $isAndroid == true ] && termux-open "https://github.com/arghya339/BingWallpaper" || open "https://github.com/arghya339/BingWallpaper"
                      exit 0
                    ;;
                  esac
                  ;;
                esac
              ;;
            SourceCode) [ $isAndroid == true ] && termux-open "https://github.com/arghya339/BingWallpaper" || open "https://github.com/arghya339/BingWallpaper" ;;
            Share) am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "https://github.com/arghya339/BingWallpaper" >/dev/null ;;
          esac
        else
          break
        fi
      done
      ;;
  esac
done
############################################################################