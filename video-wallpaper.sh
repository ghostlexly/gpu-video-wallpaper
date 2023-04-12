#!/usr/bin/env bash
# author: Tolga MALKOC | ghostlexly@gmail.com
# contributor: SwallowYourDreams | https://github.com/SwallowYourDreams
# Modified by Jason Hardman https://github.com/JayRugMan


function load_config() {
	# Source config file with MY_PIDS and LASTFILE
	# or creates it and then sources it
	if [ -f "${CONF}" ] ; then
		source <( awk 'NR!=1' ${CONF} )
	else
	    echo "[${NAME} settings]" > "${CONF}"
		echo 'MY_PIDS=()' >> "${CONF}"
		echo 'LASTFILE=""' >> "${CONF}"
		source <( awk 'NR!=1' ${CONF} )
	fi
}


function update_config() {
	# Write to config file
	# Parameters: $1: Video file

	local new_file="${1}"; shift
	echo "[${NAME} settings]" > "${CONF}"

	if [[ ! -z ${new_file} ]] ; then
		LASTFILE="${new_file}"
	fi

	echo "MY_PIDS=( ${MY_PIDS[@]} )" >> "${CONF}"
	echo "LASTFILE=${LASTFILE}" >> "${CONF}"
}


function start() {
	# Start video wallpaper playback
	# If there is an active video wallpaper, stop it first.
	if [ ${#MY_PIDS} -gt 0 ] ; then
		stop
	fi
	video_path="${1}"
	screens=`xrandr | grep " connected\|\*" | pcregrep -o1 '([0-9]{1,}[x]{1,1}[0-9+]{1,}) \('`
	for item in ${screens}; do
		"${SCRIPTDIR}"/xwinwrap -g ${item} -fdt -ni -b -nf -un -o 1.0 -- mpv -wid WID --loop --no-audio "${video_path}" & disown
		##JH "${SCRIPTDIR}"/xwinwrap -g ${item} -fdt -ni -b -nf -un -o 1.0 -- mpv -wid WID --loop --no-audio --playlist="/home/jason/.config/video-wallpaper/playlist.txt" & disown
		MY_PIDS=( ${MY_PIDS[@]} $! )
	done
	update_config "\"$video_path\""
}


function stop() {
	# Uses PIDS in conf file to kill running xwinwrap instances
	if [ ${#MY_PIDS} -gt 0 ] ; then
		echo "Stopping ${NAME}."
		for pid in ${MY_PIDS[@]}; do
			kill ${pid}
		done
	else
		echo "No active video wallpaper found."
	fi
	MY_PIDS=(); update_config "\"${LASTFILE}\""
}


function startup() {
	# Start / disable playback of video file on system startup.
	# Parameters: $1 = true|false $2 = videofile

	local is_start="${1}"; shift
	local videofile=""
	local startup_file="/home/${USER}/.config/autostart/${NAME}.desktop"

	if [[ ${is_start} == "true" ]]; then  # if true was designated by user
		echo "Enabling startup of video wallpaper."
		videofile="${1}"

	elif [[ ${is_start} == "false" ]]; then  # if false was designated by user
		echo "Disabling startup of video wallpaper."
		videofile="${LASTFILE}"

	else  # if anything else was designated by user
		usage "Illegal startup parameter"
		exit 1
	fi

	local launch_script="bash -c '\"${SCRIPTDIR}/${NAME}.sh\" --start --video-file \"${videofile}\"'"
	##JH printf "[Desktop Entry]\nType=Application\nExec=${launch_script}\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=${is_startup}\nName=${NAME}" > "/home/${USER}/.config/autostart/${NAME}.desktop"
	cat <<EOF > "${startup_file}"
[Desktop Entry]
Type=Application
Exec=${launch_script}
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=${is_startup}
Name=${NAME}
EOF
}


function file_exists() {
	# Checks if a (video) file exists. Displays and error and stops the script if it doesn't
	# $1 = the file to be checked
	if [ ! -f "${1}" ]; then
		usage "File named \"${1}\" does not exist"
		exit 1
	fi
}

# get arguments
function usage() {  #print_help
	# prints usage with optional warning string
	if [[ ! -z "${@}" ]] ; then
		echo "ERROR: ${@}" >&2
	fi

    cat <<EOF

Usage: ./${NAME}.sh [--start|--stop|--startup [true|false] ] --video-file "video_path.mp4"

--start                Start playback of video file.

--stop                 Stop active playback.

--startup              Start/disable playback of video file on system startup.

-f | --video-file      The video file

*                      Gets this helpful output

EOF
}


function and_action() {
	# Parse parameters with gnu getopt (not getopts)

	TEMP=$(getopt -o f: --long start,stop,startup:,video-file: -n "${NAME}" -- "$@")

	if [ $? != 0 ] ; then usage "BAD Option" ; exit 1 ; fi

	eval set -- "$TEMP"  # sets up getopt

	local vid_file=""
	local to_execute=""

	while true; do
		case "${1}" in

			-f | --video-file ) 
				vid_file="${2}"; shift 2
				file_exists "${vid_file}"
				;;

			--start )
				if [[ -z "${to_execute}" ]]; then
					to_execute="start"
					shift
				else
					usage "Conflicting options chosen"
					exit 1
				fi
				;;

			--stop )
				if [[ -z "${to_execute}" ]]; then
					to_execute="stop"
					shift
				else
					usage "Conflicting options chosen"
					exit 1
				fi
				;;

			--startup )
				if [[ -z "${to_execute}" ]]; then
					local is_startup="${2}"; shift 2
					to_execute="startup ${is_startup}"
				else
					usage "Conflicting options chosen"
					exit 1
				fi
				;;

			-- ) shift; break ;;  # this should handle if a paramter needing an arg has no arg
			* ) break;;
		esac
	done

	if [[ "${to_execute}" == "stop" ]] || ! ${is_startup} 2>/dev/null; then
		eval "${to_execute}"
	elif [[ ! -z "${to_execute}" ]]; then  # the only other options are start and startup
		if [[ ! -z ${vid_file} ]]; then eval "${to_execute} ${vid_file}"
		else usage "A file is required for this option"; exit 1
		fi
	else
		usage "No execution option chosen"
		exit 1
	fi
}


function main() {
	# The Main Event

	# GLOBALS
	NAME="video-wallpaper"
	SCRIPTDIR="$(dirname $(realpath "${0}"))"
	CONFDIR="/home/${USER}/.config/video-wallpaper"
	CONF="${CONFDIR}/settings.conf"  # contains PIDS and lastfile parameters
	PIDS=()
	LASTFILE=""
	if [ ! -d "$CONFDIR" ] ; then
		mkdir "$CONFDIR"
		touch "$CONF"	
	fi

	# Load Config file
	load_config  # Defines saved values of PIDS and LASTFILE

	# Execute designated action(s)
	and_action ${@}
}


# If missing parameters, show usage, otherwise, run program
if [[ -z ${@} ]]; then
	usage "No parameters provided"
    exit 1
else
	main ${@}
fi
