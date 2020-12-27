#!/bin/bash

target="_"
TARGETS=("bass" "sturgeon" "lenok" "smelt" "sparrow" "wren" "dory" "harmony" "inharmony" "mooneye" "swift" "tetra")
	
command_exists() {
        command -v "$@" > /dev/null 2>&1
}

setupDocker() {
	if ! command_exists docker
	then
   		echo "Docker not installed, installing"
		# Installs docker via convenience script to tmp dir
		curl -fsSL "https://get.docker.com" -o /tmp/get-docker.sh
		sudo sh /tmp/get-docker.sh
	else
		echo "Docker installed, skipping"
	fi
}

isTargetValid() {
	for i in "${TARGETS[@]}" 
	do
	    	if [ "$i" == "$target" ] ; then
   	     		return 1
   	    	fi
	done
	return 0
}

_askForTarget(){
	local loop=0
	local validation=0
	isTargetValid
	validation=$?
	
	until [ $validation -gt 1 ]
	do
		if [ $loop -gt 0 ] ; then 
			echo "Please choose from the list"; 
		fi
		
		read -p "Input Selection: " target
		
		loop=$(($loop+1))
		isTargetValid
		validation=$?
		echo $validation
	done
}

askForTarget(){

	echo "==========================================="	
	echo "Options"
	echo ">=========================================="	
	echo "anthias		- Asus Zenwatch 1"
	echo "sparrow		- Asus Zenwatch 2"
	echo "wren		- Asus Zenwatch 2 (rounder)"
	echo "swift		- Asus Zenwatch 3"
	echo "dory		- LG G Watch"
	echo "lenok		- LG G Watch R"
	echo "bass		- LG G Watch Urbane"
	echo "sturgeon	- Huawei Watch"
	echo "smelt		- Moto 360 2015"
	echo "harmony		- MTK6580 watches"
	echo "inharmony	- MTK6580 watches"
	echo "tetra		- Sony Smartwatch 3"
	echo "mooneye		- Ticwatch E & 6"
	echo ">=========================================="	
	
	_askForTarget
	# Remove the last line echo -en "\r"
}

setup(){
	setupDocker
	askForTarget
	echo $target
}

setup
