#!/bin/bash
# Written by: SwallowYourDreams
name="video-wallpaper"
installdir="/home/$USER/.local/bin"
xwinwrap_dl="https://github.com/mmhobi7/xwinwrap/releases/download/v0.9/xwinwrap"
dependencies=("mpv" "pcregrep" "xrandr" "python3-pyqt5")
missingDependencies=""
#installdir="/usr/local/share/$name"
files=("$name.sh" "$name.py" "gui.ui" "xwinwrap")

check_dependencies() {
	# Downloading xwinwrap
	if [ ! -f "$installdir/xwinwrap" ] ; then
		echo "$name depends on xwinwrap to run. Do you wish to download it? [y/n]"
		read input
		if [ "$input" == "y" ] ; then 
			wget "$xwinwrap_dl" -O "$installdir/xwinwrap"
			chmod +x "$installdir/xwinwrap"
		else
			echo "Dependencies unfulfilled, aborting."
			exit 1
		fi
	fi
	
	# Check for dependencies in repositories
	for d in ${dependencies[@]} ; do
		present=$(which "$d")
		if [ ${#present} -eq 0 ] ; then
			missingDependencies+=" $d"
		fi 
	done
	if [ "${#missingDependencies}" -gt 0 ] ; then
		echo "Missing dependencies:$missingDependencies. Do you wish to install them? [y/n]"
		read input
		if [ "$input" == "y" ] ; then
			sudo apt install $missingDependencies
		else
			echo "Dependencies unfulfilled, aborting."
			exit 1
		fi
	else
		echo "All dependencies are fulfilled."
	fi
}

install() {
	sudo mkdir -p $installdir
	for file in ${files[@]} ; do
		if [ "$file" != "xwinwrap" ] ; then
			sudo cp "./$file" $installdir
		fi
	done
	if [ ! -f "/.local/share/applications/$name.desktop" ] ; then
		echo "Do you wish to create a start menu entry? [y/n]"
		read input
		if [ "$input" == "y" ] ; then
			desktopFile=~/.local/share/applications/"$name".desktop
			#sudo cp "./$name.desktop" ~/.local/share/applications
			desktopEntry="[Desktop Entry]\nType=Application\nName=Video Wallpaper\nExec=$name.py\nIcon=wallpaper\nComment=Set video files as your desktop wallpaper.\nCategories=Utility\nTerminal=false\n"
			sudo printf "$desktopEntry" > "$desktopFile"
		fi
	fi
}

uninstall() {
	# Remove program files
	for file in ${files[@]} ; do
		rm "$installdir/$file"
	done
	rm ~/.local/share/applications/"$name".desktop # Menu entry
}

if [ "$1" == "" ] ; then
	echo "This script will install $name to your machine." 
	check_dependencies
	install
elif [ "$1" == "--uninstall" ] ; then
	uninstall
else
	echo "Illegal parameter."
fi
