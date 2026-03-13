#!/bin/bash

# Copyright (C) 2026, Arghyadeep Mondal <github.com/arghya339>

fileSelector() {
  allowed=${1:-images}
  [ $isAndroid == true ] && defaultPath="/sdcard" || defaultPath="$HOME"
  items_per_page=$((rows - 10))
  currentPath="$defaultPath"
  start_index=1
  selectedItem=1
  sortState=0
  hiddenState=0
  selectedButton=0

  itemsList() {
    [[ "${currentPath: -1}" != "/" ]] && currentPath="$currentPath/"
    [ "$currentPath" != "$defaultPath/" ] && items=("../") || items=()
    
    [ $hiddenState -eq 0 ] && { arg=; hiddenLabel="<showHidden>"; } || { arg="a"; hiddenLabel="<hideHidden>"; }
    image_grep="grep -E '\.(jpg|jpeg|png)$'"
    non_image_grep="grep -vE '\.(jpg|jpeg|png)$'"
    case $sortState in
      0)  sortLabel="<A-Z>";       cmd="ls -1p${arg} \"$currentPath\"" ;;
      1)  sortLabel="<Z-A>";       cmd="ls -1p${arg} \"$currentPath\" | sort -f" ;;
      2)  sortLabel="<New>";       cmd="ls -1p${arg} \"$currentPath\" | sort -fr" ;;
      3)  sortLabel="<Old>";       cmd="ls -1pt${arg} \"$currentPath\"" ;;
      4)  sortLabel="<New Images>";   cmd="ls -1ptr${arg} \"$currentPath\"" ;;
      5)  sortLabel="<Old Images>";   cmd="{ ls -1pt${arg} \"$currentPath\" | $image_grep; ls -1pt${arg} \"$currentPath\" | $non_image_grep; }" ;;
      6)  sortLabel="<Type:A-Z>";  cmd="{ ls -1ptr${arg} \"$currentPath\" | $image_grep; ls -1ptr${arg} \"$currentPath\" | $non_image_grep; }" ;;
      7)  sortLabel="<Type:Z-A>";  cmd="ls -1pX${arg} \"$currentPath\"" ;;
      8)  sortLabel="<Large>";     cmd="ls -1pXr${arg} \"$currentPath\"" ;;
      9)  sortLabel="<Small>";     cmd="ls -1pS${arg} \"$currentPath\"" ;;
      10) sortLabel="<A-Z-a-z>";   cmd="ls -1pSr${arg} \"$currentPath\"" ;;
    esac
    while IFS= read -r item; do
      items+=("$item")
    done < <(eval "$cmd")
    
    [ "$currentPath" != "$defaultPath/" ] && { itemsInfo=(""); i=1; } || { itemsInfo=(); i=0; }
    for ((i=$i; i<${#items[@]}; i++)); do
      itemsInfo+=("$(ls -ldh "$currentPath${items[i]}" | awk '{print substr($1, 1, 10), $5, $6, $7, $8}')")
    done

    totalSize=$(ls -1plh "$currentPath" | head -n 1 | awk '{print $2}')
    totalItems=${#items[@]}
  }; itemsList

  show_menu() {
    buttons=("<Select>" "$sortLabel" "$hiddenLabel" "<Back>")
    printf '\033[2J\033[3J\033[H'
    echo -n "Navigate with [↑] [↓] [←] [→]"
    [ $isMacOS == false ] && echo -n " [PGUP] [PGDN] [HOME]"
    echo -n " [ESC]"
    echo -e "\nSelect with [↵]\n"
    
    end_index=$(( start_index + items_per_page - 1 ))
    [ $end_index -gt $totalItems ] && end_index=$totalItems
    for ((i = start_index; i <= end_index; i++)); do
      item="${items[i-1]}"
      [ ${#item} -gt $((cols - 4)) ] && item="${item:0:$((cols - 7))}..."
      if [ $i -eq $selectedItem ]; then
        echo -e "${whiteBG}$buttonsSymbol $item $Reset"
      else
        [ $i -le 9 ] && echo " $i. $item" || echo "$i. $item"
      fi
    done
    
    visibleItemsCount=$((end_index - start_index + 1))
    for ((i=visibleItemsCount; i<${items_per_page}; i++)); do
      echo 
    done
    
    echo
    for ((i=0; i<=${#buttons[@]}; i++)); do
      if [ $i -eq $selectedButton ]; then
        [ $i -eq 0 ] && echo -ne "${whiteBG}$buttonsSymbol ${buttons[$i]} $Reset" || echo -ne "  ${whiteBG}$buttonsSymbol ${buttons[$i]} $Reset"
      else
        [ $i -eq 0 ] && echo -n "  ${buttons[$i]}" || echo -n "   ${buttons[$i]}"
      fi
    done
    
    echo -e "\n\ntotalSize: $totalSize"
    displayPath="$currentPath"
    [[ "${displayPath: -1}" != "/" ]] && displayPath="$displayPath/"
    echo -e "Path: $displayPath"
    [ ${#items[@]} -gt 0 ] && selectedItemName="${items[selectedItem-1]}"
    if [ -n "$selectedItemName" ]; then
      if [ "$selectedItemName" = "../" ]; then
        echo -e "DIR: Parent Directory"
      elif [ "${selectedItemName: -1}" = "/" ]; then
        echo -e "DIR: ${selectedItemName%/}"
      else
        echo -e "FILE: $selectedItemName"
      fi
    fi

    [ -n "${itemsInfo[selectedItem-1]}" ] && echo -n "ⓘ ${itemsInfo[selectedItem-1]}"
  }

  printf '\033[?25l'
  while true; do
    show_menu
    read -rsn1 key
    case $key in
      $'\E')  # ESC
        # /bin/bash -c 'read -r -p "Type any ESC key: " input && printf "You Entered: %q\n" "$input"'  # q=safelyQuoted
        read -rsn2 -t 0.1 key2
        case "$key2" in
          '[A')  # Up arrow
            if [ $selectedItem -eq 1 ]; then
              selectedItem=$totalItems
              start_index=$((totalItems - items_per_page + 1))
              [ $start_index -lt 1 ] && start_index=1
            else
              ((selectedItem--))
              [ $selectedItem -lt $start_index ] && ((start_index--))
            fi
            ;;
          '[B')  # Dn arrow
            if [ $selectedItem -eq $totalItems ]; then
              selectedItem=1
              start_index=1
            else
              ((selectedItem++))
              [ $selectedItem -ge $((start_index + items_per_page)) ] && ((start_index++))
            fi
            ;;
          '[5')  # PgUp
            read -rsn1 -t 0.1
            selectedItem=$((selectedItem - items_per_page))
            [ $selectedItem -lt 1 ] && selectedItem=1
            start_index=$selectedItem
            ;;
          '[6'|'[F')  # PgDn|END
            read -rsn1 -t 0.1
            selectedItem=$((selectedItem + items_per_page))
            [ $selectedItem -gt $totalItems ] && selectedItem=$totalItems
            start_index=$((selectedItem - items_per_page + 1))
            [ $start_index -lt 1 ] && start_index=1
            ;;
          '[C')  # right arrow
            ((selectedButton++))
            [ $selectedButton -ge ${#buttons[@]} ] && selectedButton=0 ;;
          '[D')  # left arrow
            ((selectedButton--))
            [ $selectedButton -lt 0 ] && selectedButton=$((${#buttons[@]}-1)) ;;
          '[H')  # Home
            if [ "$currentPath" != "$defaultPath/" ]; then
              currentPath="$defaultPath"
              selectedItem=1
              start_index=1
              printf '\033[2J\033[3J\033[H'
              itemsList
            fi
            ;;
          *)  # ESC alone
            if [ "$currentPath" != "$defaultPath/" ]; then
              currentPath=$(dirname "$currentPath")
              currentPath="${currentPath%/}"
              selectedItem=1
              start_index=1
              printf '\033[2J\033[3J\033[H'
              itemsList
            fi
            ;;
        esac
        ;;
      "") # Enter
        if [ $selectedButton -eq 0 ]; then
          selectedItemName="${items[selectedItem-1]}"
          if [ "$selectedItemName" = "../" ]; then
            if [ "$currentPath" != "$defaultPath/" ]; then
              currentPath=$(dirname "$currentPath")
              currentPath="${currentPath%/}"
              selectedItem=1
              start_index=1
              printf '\033[2J\033[3J\033[H'
              itemsList
            fi
          elif [[ "$selectedItemName" == */ ]]; then
            dirName="${selectedItemName%/}"
            [[ "${currentPath: -1}" != "/" ]] && currentPath="$currentPath/"
            currentPath="$currentPath${dirName}"
            selectedItem=1
            start_index=1
            printf '\033[2J\033[3J\033[H'
            itemsList
          else
            printf '\033[2J\033[3J\033[H'
            echo -e "${whiteBG}selected: $selectedItemName${Reset}"
            ext="${selectedItemName##*.}"
            if [ "$allowed" == "images" ]; then
              if [ "$ext" == "jpg" ] || [ "$ext" == "jpeg" ] || [ "$ext" == "png" ]; then
                fileName="$selectedItemName"
                [[ "${currentPath: -1}" != "/" ]] && filePath="$currentPath/$selectedItemName" || filePath="$currentPath${selectedItemName}"
                if [ $isAndroid == true ]; then
                  termux-open --send "$filePath"
                elif [ $isMacOS == true ]; then
                  open "$filePath"
                else
                  xdg-open "$filePath"
                fi
                confirmPrompt "Do you want to proceed with this image?" "ynButtons" && response=Yes || release=No
                if [ "$response" == "Yes" ]; then
                  echo "filePath: $filePath"
                  printf '\033[?25h'
                  return 0
                  break
                else
                  unset filePath
                fi
              else
                echo -e "$notice Invalid file type! You must select an image file (*.jpg, *.jpeg, *.png)."
                echo; read -p "Press Enter to continue..."
              fi
            fi
          fi
        elif [ $selectedButton -eq 1 ]; then
          ((sortState++))
          [ $sortState -gt 10 ] && sortState=0
          itemsList
          selectedItem=1
          start_index=1
        elif [ $selectedButton -eq 2 ]; then
          ((hiddenState++))
          [ $hiddenState -gt 1 ] && hiddenState=0
          itemsList
          selectedItem=1
          start_index=1
        else
          printf '\033[2J\033[3J\033[H'
          printf '\033[?25h'
          return 1
          break
        fi
        ;;
      [0-9])  # Num
        read -rsn2 -t0.5 key2
        [[ "$key2" == [0-9] ]] && key="${key}${key2}"
        if [ $key -eq 0 ]; then
          selectedItem=${#items[@]}
        elif [ $key -gt ${#items[@]} ]; then
          selectedItem=1
        else
          selectedItem=$key
        fi
        if [ $selectedItem -lt $start_index ]; then
          start_index=$selectedItem
        elif [ $selectedItem -ge $((start_index + items_per_page)) ]; then
          start_index=$((selectedItem - items_per_page + 1))
        fi
        ;;
    esac
  done
}