#!/bin/bash

# Uncomment to show warning when not running as root
# if [ $USER != "root" ]; then
#     echo "You are not rooted (current user: $USER)"
#     echo "This can cause issues while using the program"
# fi

PROXCONF=$(locate proxychains | grep -E '\.conf$' | head -n 1)

if [[ -z "$PROXCONF" ]]
then
    DEFAULT_CONF="/etc/proxychains.conf"
    if [[ -f "$DEFAULT_CONF" ]]
    then
        PROXCONF="$DEFAULT_CONF"
    else
        echo "Error: Could not find proxychains config file."
        if [[ $(which proxychains) != /usr/bin/proxychains ]]
        then
            echo "Error: proxychains is not installed"
        fi
        exit 1
    fi
fi

case $1 in
    -E|--edit)  
        echo "Opening proxychains config file: $PROXCONF"
        sudo nano "$PROXCONF"
    ;;

    -l|--list)
        echo "Listing proxies..."
        echo ""
        echo "Type     | IP           | Port"
        echo "---------|--------------|------"
        grep -E '^\s*(socks4|socks5|http|https)\s+' "$PROXCONF" | awk '{ printf "%-8s | %-12s | %s\n", $1, $2, $3 }'
    ;;

    -el|--edit-list)
        shift

        ADD_MODE=false
        PROXY_LINES=()

        while [[ "$1" =~ ^- ]]
        do
            case "$1" in
                -a|--add)
                    ADD_MODE=true
                    shift
                ;;

                -1|-2|-3|-4|-5)
                    shift
                    if [[ -n "$1" ]]
                    then
                        PROXY_LINES+=("$1")
                        shift
                    fi
                ;;

                *)
                    echo "Unknown option: $1"
                    exit 1
                ;;
            esac
        done

        if [[ ${#PROXY_LINES[@]} -eq 0 ]]
        then
            echo -n "No proxies provided. Do you want to manually edit the file? [y/n]: "
            while true
            do
                read confirm1
                case "$confirm1" in
                    y)
                        sudo nano "$PROXCONF"
                        break
                    ;;

                    n)
                        echo "Abort."
                        break
                    ;;

                    *)
                        echo -n "Incorrect answer, please answer again with 'y' or 'n': "
                    ;;
                esac
            done
        else
            echo "Updating proxy list..."

            TMP_CONF=$(mktemp)
            grep -vE '^\s*(socks4|socks5|http|https)\s+' "$PROXCONF" > "$TMP_CONF"

            cat "$TMP_CONF" > "$PROXCONF"
            for line in "${PROXY_LINES[@]}"
            do
                echo "$line" >> "$PROXCONF"
            done

            echo "Proxy list updated in $PROXCONF"
        fi
    ;;

    -h|-H|-?|--help)
        echo "> $(basename "$0") arguments:"
        echo "> -E OR --edit                # Edit entire proxychains config file"
        echo "> --list OR -l                # List active proxies"
        echo "> --edit-list OR -el          # Edit proxy list only"
        echo "> -h OR any help flag         # Show this help message"
    ;;

    *)
        echo "Invalid argument. Use -h for help."
    ;;
esac
