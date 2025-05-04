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
            echo "Do you want to install it?[y/n]"
            while true
            do
                read confirm0
                case "$confirm0" in
                    y)
                        sudo apt install proxychains
                        echo ""
                        echo "You've installed proxychains. Run 'proxyfix -h' for help" 
                        exit 0
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

    -ela|--edit-list-add)
        ADD_MODE=true
        shift
        set -- -el "$@"
        ;&
    -elcl|--edit-list-clear)
        CLEAR_MODE=true
        shift
        set -- -el "$@"
        ;&
    -el|--edit-list)
        shift

        ADD_MODE=${ADD_MODE:-false}
        CLEAR_MODE=${CLEAR_MODE:-false}
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

            if [[ "$CLEAR_MODE" == true ]]
            then
                echo "# Cleared proxy list" >> "$PROXCONF"
            fi

            for line in "${PROXY_LINES[@]}"
            do
                echo "$line" >> "$PROXCONF"
            done

            echo "Proxy list updated in $PROXCONF"
            rm "$TMP_CONF"
        fi
    ;;

    -cl|--clear)
        echo "Are you sure that you want to clear the proxy list? [y/n]"
        while true
        do
            read confirm2
            case "$confirm2" in
                y)
                    echo "Clearing proxy list in $PROXCONF..."
                    TMP_CONF=$(mktemp)
                    grep -vE '^\s*(socks4|socks5|http|https)\s+' "$PROXCONF" > "$TMP_CONF"
                    cat "$TMP_CONF" > "$PROXCONF"
                    rm "$TMP_CONF"
                    echo "Proxy list cleared."
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
    ;;

    -h|-H|-?|--help)
        echo "> $(basename "$0") arguments:"
        echo "> -E OR --edit                # Edit entire proxychains config file"
        echo "> -l OR --list                # List active proxies"
        echo "> -el OR --edit-list          # Replace proxy list"
        echo "> -ela OR --edit-list-add     # Add to current proxy list"
        echo "> -elcl OR --edit-list-clear  # Clear proxy list before editing"
        echo "> -cl OR --clear              # Just clear proxy list"
        echo "> -h OR any help flag         # Show this help message"
    ;;

    *)
        echo "Invalid argument. Use -h for help."
    ;;
esac
