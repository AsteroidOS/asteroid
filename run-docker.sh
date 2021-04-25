#!/bin/bash
VERSION="1.0.0"
TARGET="_"
TARGETS=("bass" "sturgeon" "lenok" "smelt" "sparrow" "wren" "dory" "harmony" "inharmony" "mooneye" "swift" "tetra")

# Function taken from somewhere else to check if a command exists
command_exists() {
    command -v "$@" > /dev/null 2>&1
}

echoln(){
    echo ""
    echo $1
    echo ""
}

# Installs docker if it does not exist
checkDocker() {
    if ! command_exists docker
    then
        echoln "# Docker not installed, Please install before continuing"
        exit
    else
        echoln "# Docker installed, skipping"
    fi
}

# Builds the image, it also updates if the image exists
buildDockerImage(){
    echoln "# Building / Updating docker image"
    sudo docker build --tag asteroidos-toolchain .
}

# Removes the previous docker container
rmPreviousContainer(){
    echoln "# Deleting previous docker file"
    sudo docker rm -f asteroidos-toolchain
}

# Executes the build
executeBuild(){
    echoln "# Executing build for $TARGET"
    sudo docker run --name asteroidos-toolchain -it -v /etc/passwd:/etc/passwd -u $(id -u):$(id -g) -v "$HOME/.gitconfig:/$HOME/.gitconfig" -v "$(pwd):/asteroid" asteroidos-toolchain bash -c "source ./prepare-build.sh $TARGET && bitbake asteroid-image"
}

# Is the build target valid?
isTargetValid() {
    for i in "${TARGETS[@]}"
    do
        if [ "$i" == "$TARGET" ] ; then
            return
        fi
    done
    echo "Target is not valid"
    exit
}

# Outputs possible build targets
printBuildTargets(){
    echo "==========================================="
    echo "Build Targets"
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
}

printVersion(){
    echo "Version: $VERSION"
}

printHelp(){
    echo "This is the easy docker build script!"
    echo " Arguments:"
    echo "	-v	: Outputs version"
    echo "	-t	: Outputs targets"
    echo "	-h	: Outputs this message"
    echo "	TARGET	: Target from -t, will be validified then built for"
}

# The main function of this program, does all the main work
main(){
    checkDocker
    buildDockerImage
    rmPreviousContainer
    executeBuild
    echoln "# Finished, goodbye"
    exit
}

# Handle arguments
for var in "$@"
do
    case "$var" in
        "-h")
            printHelp
            exit
        ;;
        "-v")
            printVersion
            exit
        ;;
        "-t")
            printBuildTargets
            exit
        ;;
        *)
        ;;
    esac
done

if [ "$1" != "" ] ; then
	TARGET="$1"
	isTargetValid
	main
fi

echo "# Yeah... I ain't running without a target. Run with '-h' to figure out what to do"

