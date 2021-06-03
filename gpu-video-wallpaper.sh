#!/usr/bin/env bash
# author: Tolga MALKOC | ghostlexly@gmail.com
# contributor: SwallowYourDreams | https://github.com/SwallowYourDreams

name="gpu-video-wallpaper"
scriptdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
conf="$scriptdir/settings.conf"
if [ -f "$conf" ] ; then
	source "$conf" # To do: Find a more elegant way of reading variables from the config file. The shell will throw an error because it stumbles over the [gpu-video-wallpaper settings] section. For now, this is tolerable.
else
	echo 'pid=""' > "$conf"
fi

# Write to config file
# Parameters: $1: pid | $2: Video file
update_config() {
	echo "[$name settings]" > "$conf"
	if [ ${#1} -gt 0 ] ; then
		pid=$1
	else
		pid=""
	fi
	if [ ${#2} -gt 0 ] ; then
		lastfile="$2"
	fi
	echo $pid
	echo "pid=$pid" >> "$conf"
	echo "lastfile=$lastfile" >> "$conf"
}

# Start video wallpaper playback
start() {
	# If there is an active video wallpaper, stop it first.
	if [ ${#pid} -gt 0 ] ; then
		stop
	fi
	VIDEO_PATH="$1"
	SCREENS=`xrandr | grep " connected\|\*" | pcregrep -o1 '([0-9]{1,}[x]{1,1}[0-9+]{1,}) \('`
	for item in $SCREENS
	do
		"$scriptdir"/xwinwrap -g $item -fdt -ni -b -nf -un -o 1.0 -- mpv -wid WID --loop --no-audio "$VIDEO_PATH" & disown
	done
	update_config $! "$VIDEO_PATH"
}

stop() {
	if [ ${#pid} -gt 0 ] ; then
		echo "Stopping $name."
		kill "$pid"
	else
		echo "No active video wallpaper found."
	fi
	update_config
}

startup() {
	echo "Adding $name to system startup."
	LAUNCH_SCRIPT="bash -c '\"$scriptdir/gpu-video-wallpaper.sh\" --start  \"${@:2}\"'"
	printf "[Desktop Entry]\nType=Application\nExec=$LAUNCH_SCRIPT\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName=$name" > ~/.config/autostart/gpu-video-wallpaper.desktop
}

# get arguments
print_help() {
    echo "Usage: ./gpu-video-wallpaper.sh [--stop] [--startup] \"video_path.mp4\""
    echo ""
    echo "--stop  Kill all gpu-video-wallpaper.sh processes."
    echo ""
    echo "--startup  Start gpu-video-wallpaper.sh on Ubuntu startup."
    echo ""
}

# If missing parameters, show help
if [ $# = 0 ]
    then print_help
        exit 1
fi

# Parse parameters
while true
    do if [ $# -gt 0 ]
        then case $1 in
            --startup*)
                startup "${@}"
                exit 0
            ;;
            
			--start*)
				start "$2"
				exit 0
			;;
			
            --stop*)
				stop
				exit 2
            ;;

            --*)
                print_help
                exit 1
            ;;

            *)
                break
            ;;
        esac
    else
        echo "No video path given!"
        exit 2
    fi
done
