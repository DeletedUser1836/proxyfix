#!/bin/bash

#---==If u want to see an alert because u are not rooted un comment code below==---
if [ $USER != "root"]
then
    echo "You are not rooted (current user: $USER)"
    echo "This can cause issues while using the program"
fi

# Find proxychains config file
PROXCONF=$(locate proxychains | grep -E '\.conf$' | head -n 1)

# Going to deafult if locate fails
if [[ -z "$PROXCONF" ]]
then
    DEFAULT_CONF="/etc/proxychains.conf"
    if [[ -f "$DEFAULT_CONF" ]]
    then
        PROXCONF="$DEFAULT_CONF"
    else
        echo "Error: Could not find proxychains config file."
        if [ $(which proxychains) != /usr/bin/proxychains ]
            echo "Error: proxychains is not installed"
        fi
        exit 1
    fi
fi

echo "Config file detected: $PROXCONF"

# Edit the entire config file
if [[ "$1" == "-E" || "$1" == "--edit" ]]
then
    echo "Opening proxychains config file: $PROXCONF"
    sudo nano "$PROXCONF"

# List proxies
elif [[ "$1" == "--list" || "$1" == "-l" ]]
then
    echo "Listing proxies..."
    echo ""
    echo "Type     | IP           | Port"
    echo "---------|--------------|------"
    grep -E '^\s*(socks4|socks5|http|https)\s+' "$PROXCONF" | awk '{ printf "%-8s | %-12s | %s\n", $1, $2, $3 }'

# Edit only the list of proxies
elif [[ "$1" == "--edit-list" || "$1" == "-el" ]]
then
    shift

    # Flags
    ADD_MODE=false
    PROXY_LINES=()

    # Parse arguments
    while [[ "$1" =~ ^- ]]
    do
        case "$1"in
        
            -a|--add) ADD_MODE=true;;

            -1|-2|-3|-4|-5) shift; PROXY_LINES+=("$1");;

            *) echo "Unknown option: $1"; exit 1;;
    
        esac
        shift
    done

    # If no proxies were provided, open manual edit
    if [[ ${#PROXY_LINES[@]} -eq 0 ]]
    then
        echo "No proxies provided. Opening config file for manual editing..."
        sudo nano "$PROXCONF"
    else
        echo "Updating proxy list..."
        
        # Filter config to remove old proxy lines
        TMP_CONF=$(mktemp)
        grep -vE '^\s*(socks4|socks5|http|https)\s+' "$PROXCONF" > "$TMP_CONF"

        # Append or replace
        if [[ "$ADD_MODE" == true ]]
        then
            cat "$TMP_CONF" > "$PROXCONF"

            for line in "${PROXY_LINES[@]}"
            do
                echo "$line" >> "$PROXCONF"
            done
        else
            cat "$TMP_CONF" > "$PROXCONF"

            for line in "${PROXY_LINES[@]}"
            do
                echo "$line" >> "$PROXCONF"
            done
        fi

        echo "Proxy list updated in $PROXCONF"
    fi

# Help message
elif [[ "$1" == "-h" || "$1" == "-H" || "$1" == "-?" || "$1" == "--help" ]]
then
    echo "> $(basename "$0") arguments:"
    echo "> -E OR --edit                # Edit entire proxychains config file"
    echo "> --list OR -l                # List active proxies"
    echo "> --edit-list OR -el          # Edit proxy list only"
    echo "> -h OR --help                # Show this help message"

# Invalid command
else
    echo "Invalid argument. Use -h for help."
fi