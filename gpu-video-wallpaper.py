#!/usr/bin/env python3
import sys
import os
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
		self.shellScript = self.scriptDir.replace(" ", "\ ") + "gpu-video-wallpaper.sh"
		self.dependencies = ["mpv", "pcregrep", "xrandr"]
		self.missingDependencies = self.checkDependencies()
		self.name = "gpu-video-wallpaper"
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
		self.button_autostart.clicked.connect(self.autostart)
		#Startup
		if len(self.missingDependencies) > 0:
			self.statusbar.showMessage("Error: missing dependencies: " + str(self.missingDependencies) + ". Please run the installer again.")
			self.button_start.setEnabled(False)
			self.button_stop.setEnabled(False)

	def selectFile(self, event):
		dialogue = QFileDialog(self)
		dialogue.setFileMode(QFileDialog.ExistingFile)
		if len(self.directory.text()) > 0:
			dialogue.setDirectory(self.directory.text())
		file = dialogue.getOpenFileName(self, "Select video file")
		if len(file[0]) > 0:
			self.directory.setText(file[0])
	
	def start(self, event):
		if(self.fileSelected()):
			exitcode = os.system(self.shellScript + ' --start "' + self.directory.text() + '"')
			if exitcode > 0:
				self.statusbar.showMessage("Error: could not start playback.")
			else:
				self.statusbar.showMessage("Playback started.")

	def stop(self, event):
		os.system(self.shellScript + " --stop")
		self.statusbar.showMessage("Playback stopped.")
	
	def autostart(self,event):
		if self.fileSelected():
			os.system(self.shellScript + " --startup " + self.directory.text())
			self.statusbar.showMessage("Set video wallpaper as autostart.") 
	
	def fileSelected(self):
		path = self.directory.text()
		if len(path) > 0 and os.path.isfile(path):
			return True
		else:
			self.statusbar.showMessage("No video file selected.")
			return False
	
	def checkDependencies(self):
		missingDependencies = []
		for d in self.dependencies:
			missing = os.system("which " + d)
			if missing:
				missingDependencies.append(d)
		return missingDependencies

# Main method
if __name__ == "__main__":
	app = QtWidgets.QApplication(sys.argv)
	# Main window
	w = MainWindow()
	sys.exit(app.exec_())
