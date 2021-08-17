#!/usr/bin/env python3
import sys
import os
import getpass
import configparser
from PyQt5 import QtWidgets, QtGui, uic
from PyQt5.QtWidgets import QFileDialog
from PyQt5.QtGui import QIcon

class MainWindow(QtWidgets.QMainWindow):
	def __init__(self, verbose = False):
		# Inherited class __init__ method
		super(MainWindow, self).__init__()
		# Variables
		self.scriptDir = os.path.dirname(os.path.realpath(__file__)) + "/"
		self.name = "video-wallpaper"
		self.shellScript = self.scriptDir.replace(" ", "\ ") + self.name + ".sh"
		self.dependencies = ["mpv", "pcregrep", "xrandr"]
		self.missingDependencies = self.checkDependencies()
		self.autostartFile = "/home/" + getpass.getuser() + "/.config/autostart/" + self.name + ".desktop"
		# Load external .ui file
		uic.loadUi( self.scriptDir + "gui.ui", self)
		self.show()
		# Parse config
		self.parser = configparser.RawConfigParser()
		configFile = self.scriptDir + "/settings.conf"
		if os.path.isfile(configFile):
			self.parser.read(configFile)
			lastFile = self.parser.get(self.name + " settings", "lastfile")
			if len(lastFile) > 0:
				self.directory.setText(lastFile)
		# UI functionality
		self.button_browse.clicked.connect(self.selectFile)
		self.button_start.clicked.connect(self.start)
		self.button_stop.clicked.connect(self.stop)
		self.checkbox_autostart.setChecked(self.getAutostart())
		self.checkbox_autostart.toggled.connect(self.autostart, not self.checkbox_autostart.isChecked())
		#Startup
		if len(self.missingDependencies) > 0:
			self.statusbar.showMessage("Error: missing dependencies: " + str(self.missingDependencies) + ". Please run the installer again.")
			print("Missing dependencies: " + str(self.missingDependencies))
			self.button_start.setEnabled(False)
			self.button_stop.setEnabled(False)
			self.checkbox_autostart.setEnabled(False)
		else:
			print("All dependencies fulfilled.")

	def selectFile(self, event):
		dialogue = QFileDialog(self)
		dialogue.setFileMode(QFileDialog.ExistingFile)
		if len(self.directory.text()) > 0:
			dialogue.setDirectory(self.directory.text())
		file = dialogue.getOpenFileName(self, "Select video file")
		if len(file[0]) > 0:
			self.directory.setText(file[0])
	
	def start(self):
		if(self.fileSelected()):
			exitcode = os.system(self.shellScript + ' --start "' + self.directory.text() + '"')
			if exitcode > 0:
				self.statusbar.showMessage("Error: could not start playback.")
			else:
				self.statusbar.showMessage("Playback is running.")

	def stop(self):
		os.system(self.shellScript + " --stop")
		self.statusbar.showMessage("Playback stopped.")
	
	def autostart(self, enable):
		if self.fileSelected():
			if(enable):
				self.statusbar.showMessage("Wallpaper autostart enabled.") 
			else:
				self.statusbar.showMessage("Wallpaper autostart disabled.")
			os.system(self.shellScript + " --startup " + str(enable).lower() + " " + self.directory.text())
			
	def getAutostart(self):
		if os.path.isfile(self.autostartFile):
			cat = str(os.popen("cat " + self.autostartFile + "| grep -Po 'X-GNOME-Autostart-enabled=\K.*'").read()).strip()
			cat = True if cat == "true" else False
			return cat
		else:
			return False
	
	def fileSelected(self):
		path = self.directory.text()
		if len(path) > 0 and os.path.isfile(path):
			return True
		else:
			self.statusbar.showMessage("No video file selected.")
			return False
	
	def checkDependencies(self):
		missingDependencies = []
		print("Checking for missing dependencies:")
		for d in self.dependencies:
			missing = os.system("which " + d)
			if missing:
				missingDependencies.append(d)
		print ("./xwinwrap")
		if not os.path.isfile(self.scriptDir + "/xwinwrap"):
			missingDependencies.append("xwinwrap")
		return missingDependencies

# Main method
if __name__ == "__main__":
	app = QtWidgets.QApplication(sys.argv)
	# Main window
	w = MainWindow()
	sys.exit(app.exec_())
