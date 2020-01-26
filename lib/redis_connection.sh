#!/bin/bash

set -o posix;

# Is current user root?
function is_root() {
    if [ "$USER" != 'root' ]; then
        # Not root return error
        return 1;
    fi
    # Root return OK
    return 0;
}

function create_redis_connection() {
    if (! do_connect) then
        return 1;
    fi
    # Start a redis instance
    systemctl start redis;
    if [ "$?" != 0 ]; then
        echo "There was a problem starting redis!"\
        "Try running 'systemctl status redis' to see why Redis failed to start."\
        "This is a Fatal Error, Exiting" >&2;
        # Return failure code
        return 1;
    fi
    
    echo "Redis Started Sucessfully!";
    return 0;
}

function destroy_redis_connection() {
    if (! do_disconnect) then
        return 1;
    fi

    # Stop redis instance and test that it's down
    systemctl stop redis && redis_is_down=$(redis-cli ping);
    if [[ "$?" != 0 ]] && [[ $redis_is_down == 'PONG' ]]; then
        echo "REDIS DID NOT SHUT DOWN PROPERLY!!!";
        echo "YOU MAY HAVE LOST DATA!!!";
        echo "CHECK YOUR REDIS INSTALL AND FILES RIGHT AWAY!!!";
        echo "CRASHING AND BURNING...";
        exit 128;
    fi

    echo "Redis shut down successfully, connection closed.";
    return 0;
}

function do_connect() {
    while true; do
        read -p "Would you like to connect to Redis? [Y, N]" choice;
        
        case $choice in
            'Y' | 'y')
                return 0;
            ;;
            'N' | 'n')
                return 1;
            ;;
            *)
                echo "Invalid option press the Y or the N key.";
        esac
    done
}

function do_disconnect() {
    while true; do
        read -p "Are you sure you want to disconnect from Redis?  This will close your connection to Redis and stop the Redis service! [Y, N]" choice;
        
        case $choice in
            'Y' | 'y')
                return 0;
            ;;
            'N' | 'n')
                return 1;
            ;;
            *)
                echo "Invalid option press the Y or the N key.";
        esac
    done
}

# Checks the connection to Redis
function has_redis_connection() {
    # Ping redis server
    redis_pinged=$(redis-cli ping)
    if [[ $redis_pinged != 'PONG' ]]; then
        return 1; # Return error status
    fi
    
    return 0
}

# Make sure script runs as root.
if [ "$USER" != 'root' ]; then
    echo "This script must be ran as root. [redis_connection.sh]";
    exit 1;
fi