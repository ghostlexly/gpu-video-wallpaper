#!/usr/bin/env bash
# author: Tolga MALKOC | ghostlexly@gmail.com
# contributor: SwallowYourDreams | https://github.com/SwallowYourDreams

name="video-wallpaper"
scriptdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
conf="$scriptdir/settings.conf"
if [ -f "$conf" ] ; then
	source "$conf" &> /dev/null # To do: Find a more elegant way of reading variables from the config file. The shell will throw an error because it stumbles over the [video-wallpaper settings] section. For now, this is tolerable; the error message will be sent to /dev/null.
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
		"$scriptdir"/xwinwrap -g $item -fdt -ni -b -ov -nf -un -o 1.0 -- mpv -wid WID --loop --no-audio "$VIDEO_PATH" & disown
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

# Start / disable playback of video file on system startup.
# Parameters: $1 = true|false
startup() {
	startup=""
	if [ "$2" == "true" ] || [ "$2" == "" ] ; then
		echo "Adding $name to system startup."
		startup="true"
	elif [ "$2" == "false" ] ; then
		echo "Disabling startup."
		startup="false"
	else
		echo "Illegal startup parameter."
		exit 1
	fi
	LAUNCH_SCRIPT="bash -c '\"$scriptdir/$name.sh\" --start  \"${@:2}\"'"
	printf "[Desktop Entry]\nType=Application\nExec=$LAUNCH_SCRIPT\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=$startup\nName=$name" > "/home/$USER/.config/autostart/$name.desktop"
}

# get arguments
print_help() {
    echo "Usage: ./$name.sh [--start] [--stop] [--startup true|false] \"video_path.mp4\""
    echo ""
    echo "--start Start playback of video file."
    echo ""
    echo "--stop Stop active playback."
    echo ""
    echo "--startup Start/disable playback of video file on system startup."
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
