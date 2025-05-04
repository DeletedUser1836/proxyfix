#!/bin/bash

# Find proxychains config file
PROXCONF=$(locate proxychains | grep -E '\.conf$' | head -n 1)
echo "Config file detected: $PROXCONF"

#edit the whole file with nano
if [[ "$1" == "-E" || "--edit"]]; then
    echo "Opening proxychains config file: $PROXCONF"
    sudo nano "$PROXCONF"

#list proxies
elif [[ "$1" == "--list" || "$1" == "-l" ]]; then
    echo "Listing proxies..."; echo " "
    echo "type | ip | port|"
    grep -E '^socks|^http|^https' "$PROXCONF"

#edit the list of proxies
elif [[ "$1" == "--edit-list" || "$1" == "-el" ]]; then
    echo "Editing active proxies list..."
    sudo nano "$PROXCONF"

#help page
elif [[ "$1" == "-h" || "$1" == "-H" || "$1" == "-?" || "$1" == "--help" ]]; then
    echo "> proxfix arguments:"
    echo "> proxfix -E OR --edit                # Edit whole proxychains config file"
    echo "> proxfix --list OR -l                # List active proxies"
    echo "> proxfix --edit-list OR -el          # Edit proxy list only"
#invalid command 
else
    echo "Invalid argument. Use -h for help."
fi
