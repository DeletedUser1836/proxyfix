#!/bin/bash

# Uncomment to show warning when not running as root
# if [ $USER != "root" ]; then
#     echo "You are not rooted (current user: $USER)"
#     echo "This can cause issues while using the program"
# fi

PROXCONF=$(locate proxychains | grep -E '\.conf$' | head -n 1)

# === Default global settings for profile system ===
DEFAULT_PROFILE_DIR=$(cat "$DEFAULT_PROFILE_DIR_FILE")
DEFAULT_PROFILE_VIEWER=$(cat "$DEFAULT_PROFILE_VIEWER_FILE")
DEFAULT_PROFILE_DIR_FILE="$HOME/.proxyfix_default_profiles_dir"
DEFAULT_PROFILE_VIEWER_FILE="$HOME/.proxyfix_default_profile_viewer"

if [[ ! -f "$DEFAULT_PROFILE_DIR_FILE" ]]
then
    echo "$HOME/ProxyFixProfiles" > "$DEFAULT_PROFILE_DIR_FILE"
fi

if [[ ! -f "$DEFAULT_PROFILE_VIEWER_FILE" ]]
then
    echo "cat" > "$DEFAULT_PROFILE_VIEWER_FILE"
fi

ensure_profile_folder_exists()
{
    if [[ ! -d "$DEFAULT_PROFILE_FOLDER" ]]
    then
        mkdir -p "$DEFAULT_PROFILE_FOLDER"
        echo "No default profiles folder set. Created: $DEFAULT_PROFILE_FOLDER"
        echo "To change it, use: proxyfix --set-default-profiles-folder <path>"
    fi
}
ensure_profile_name_was_given()
{
    if [[ -z "$PROFILE_NAME" ]]
    then
        echo "You must provide a profile name. Usage: proxyfix --save-profile <name>"
        exit 1
    fi
}
profile_not_found_404()
{
    if [[ ! -f "$PROFILE_PATH" ]]
    then
        echo "Profile '$PROFILE_NAME' not found(404) in $DEFAULT_PROFILE_FOLDER"
        exit 404
    fi
}

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
    # === Profiles Part  ===
    
    -ldpf|--locate-default-profiles-folder)
        if [[ -f "$DEFAULT_PROFILE_DIR_FILE" ]]
        then
            echo "Current default profiles folder:"
            echo "$DEFAULT_PROFILE_DIR"
        else
            echo "No default profiles folder set."
            echo "Use '--set-default-profiles-folder <path>' to set one."
        fi
    ;;

    -sdpf|--set-default-profiles-folder)
        if [[ -z "$2" ]]
        then
            echo "Error: You must provide a folder path."
            echo "Usage: --set-default-profiles-folder <path>"
        else
            mkdir -p "$2"
            echo "$2" > "$DEFAULT_PROFILE_DIR_FILE"
            echo "Default profiles folder set to: $2"
        fi
        shift
    ;;

    -sp|--save-profile)
        PROFILE_NAME="$2"

        ensure_profile_name_was_given

        ensure_profile_folder_exists

        PROFILE_PATH="${DEFAULT_PROFILE_FOLDER}/${PROFILE_NAME}.conf"

        grep -E '^\s*(socks4|socks5|http|https)\s+' "$PROXCONF" > "$PROFILE_PATH"

        echo "Saved profile '$PROFILE_NAME' to: $PROFILE_PATH"
    ;;

    -cp|--change-profile)
        PROFILE_NAME="$2"

        ensure_profile_name_was_given

        ensure_profile_folder_exists

        PROFILE_PATH="${DEFAULT_PROFILE_FOLDER}/${PROFILE_NAME}.conf"

        profile_not_found_404

        echo -n "Are you sure you want to replace contents of $PROXCONF with profile '$PROFILE_NAME'? [y/n]: "
        while true
        do
            read confirm_cp
            case "$confirm_cp" in
                y)
                    echo "Replacing contents of $PROXCONF with profile '$PROFILE_NAME'..."
                    TMP_CONF=$(mktemp)
                    grep -vE '^\s*(socks4|socks5|http|https)\s+' "$PROXCONF" > "$TMP_CONF"
                    cat "$TMP_CONF" > "$PROXCONF"
                    cat "$PROFILE_PATH" >> "$PROXCONF"
                    rm "$TMP_CONF"
                    echo "Profile '$PROFILE_NAME' applied to $PROXCONF"
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

    -ep|--edit-profile)
        PROFILE_NAME="$2"

        ensure_profile_name_was_given

        ensure_profile_folder_exists

        PROFILE_PATH="${DEFAULT_PROFILE_FOLDER}/${PROFILE_NAME}.conf"

        profile_not_found_404

        echo "Opening profile '$PROFILE_NAME' for editing..."
        ${DEFAULT_PROFILE_VIEWER:-nano} "$PROFILE_PATH"
    ;;

    -dp|--delete-profile)
        PROFILE_NAME="$2"

        ensure_profile_name_was_given

        ensure_profile_folder_exists

        PROFILE_PATH="${DEFAULT_PROFILE_FOLDER}/${PROFILE_NAME}.conf"

        profile_not_found_404

        echo -n "Are you sure you want to delete profile '$PROFILE_NAME'? [y/n]: "
        while true
        do
            read confirm_del
            case "$confirm_del" in
                y)
                    rm "$PROFILE_PATH"
                    echo "Profile '$PROFILE_NAME' deleted."
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

    -lp|--list-profiles)
        ensure_profile_folder_exists

        echo "Available profiles in $DEFAULT_PROFILE_FOLDER:"
        if ls "$DEFAULT_PROFILE_FOLDER"/*.conf &>/dev/null
        then
            for file in "$DEFAULT_PROFILE_FOLDER"/*.conf
            do
                basename "$file" .conf
            done
        else
            echo "(No profiles found)"
        fi
    ;;

        -vp|--view-profile)
        PROFILE_NAME="$2"

        ensure_profile_name_was_given
        ensure_profile_folder_exists

        PROFILE_PATH="${DEFAULT_PROFILE_FOLDER}/${PROFILE_NAME}.conf"
        profile_not_found_404

        if [[ "$DEFAULT_PROFILE_VIEWER" != "cat" && "$DEFAULT_PROFILE_VIEWER" != "less" && "$DEFAULT_PROFILE_VIEWER" != "more" ]]
        then
            echo "Unknown default viewer '$DEFAULT_PROFILE_VIEWER'. Falling back to 'cat'."
            DEFAULT_PROFILE_VIEWER="cat"
        fi

        $DEFAULT_PROFILE_VIEWER "$PROFILE_PATH"
    ;;

    -vpm|--view-profile-more)
        PROFILE_NAME="$2"

        ensure_profile_name_was_given
        ensure_profile_folder_exists

        PROFILE_PATH="${DEFAULT_PROFILE_FOLDER}/${PROFILE_NAME}.conf"
        profile_not_found_404

        more "$PROFILE_PATH"
    ;;

    -vpl|--view-profile-less)
        PROFILE_NAME="$2"

        ensure_profile_name_was_given
        ensure_profile_folder_exists

        PROFILE_PATH="${DEFAULT_PROFILE_FOLDER}/${PROFILE_NAME}.conf"
        profile_not_found_404

        less "$PROFILE_PATH"
    ;;

    -vpc|--view-profile-cat)
        PROFILE_NAME="$2"

        ensure_profile_name_was_given
        ensure_profile_folder_exists

        PROFILE_PATH="${DEFAULT_PROFILE_FOLDER}/${PROFILE_NAME}.conf"
        profile_not_found_404

        cat "$PROFILE_PATH"
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

        -hp|--help-profiles|-?p)
        echo ""
        echo "Profile management options:"
        echo "  -sp,  --save-profile <name>                     #Save current proxy list as a named profile"
        echo "  -cp,  --change-profile <name>                   #Replace proxychains.conf with selected profile"
        echo "  -ep,  --edit-profile <name>                     #Edit selected profile using the default editor"
        echo "  -dp,  --delete-profile <name>                   #Delete selected profile (with confirmation)"
        echo "  -lp,  --list-profiles                           #Show list of all saved profiles"
        echo "  -vp,  --view-profile <name>                     #View profile content using default or chosen viewer"
        echo "        --view-profile-more / -vpm                #View profile with 'more'"
        echo "        --view-profile-less / -vpl                #View profile with 'less'"
        echo "        --view-profile-cat / -vpc                 #View profile with 'cat'"
        echo ""
        echo "  -cdpv,--change-default-profile-view <viewer>    #Change default viewer to: cat / less / more"
        echo "  -sdpf,--set-default-profiles-folder <path>      #Set default folder for profiles"
        echo "  -ldpf,--locate-default-profiles-folder          #Show current default profile folder"

        echo "Note:"
        echo "  If no default profile folder is set, one will be created at ~/ProxyFixProfiles"
    ;;

    *)
        echo "Invalid argument. Use -h for help."
    ;;
esac
