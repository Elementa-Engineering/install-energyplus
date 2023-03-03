#!/bin/bash
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }
# Check if EnergyPlus env variables exist already. If not use these defaults
if [[ -z "${ENERGYPLUS_VERSION}" ]]; then
  export ENERGYPLUS_VERSION=9.2.0
fi
if [[ -z "${ENERGYPLUS_SHA}" ]]; then
  export ENERGYPLUS_SHA=921312fa1d
fi
if [[ -z "${ENERGYPLUS_INSTALL_VERSION}" ]]; then
  export ENERGYPLUS_INSTALL_VERSION=9-2-0
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if version_gt $ENERGYPLUS_VERSION 9.3.0; then
    export EXT="sh"
    export PLATFORM=Linux-Ubuntu18.04
  else
    export EXT="sh"
    export PLATFORM=Linux
  fi
  export ATTCHBASE=97
  export ATTCHNUM=8230
elif [[ "$OSTYPE" == "darwin"* ]]; then
  if version_gt $ENERGYPLUS_VERSION 9.3.0; then
    export EXT=dmg
    export PLATFORM=Darwin-macOS10.15
  else
    export EXT=dmg
    export PLATFORM=Darwin
  fi
  export ATTCHBASE=98
  export ATTCHNUM=8232
elif [[ "$OSTYPE" == "win"* || "$OSTYPE" == "msys"* ]]; then
  export EXT=exe
  export PLATFORM=Windows
  export ATTCHBASE=86
  export ATTCHNUM=8231
fi
# Download EnergyPlus executable
ENERGYPLUS_DOWNLOAD_BASE_URL=https://github.com/NREL/EnergyPlus/releases/download/v$ENERGYPLUS_VERSION
ENERGYPLUS_DOWNLOAD_FILENAME=EnergyPlus-$ENERGYPLUS_VERSION-$ENERGYPLUS_SHA-$PLATFORM-x86_64
ENERGYPLUS_DOWNLOAD_URL=$ENERGYPLUS_DOWNLOAD_BASE_URL/$ENERGYPLUS_DOWNLOAD_FILENAME.$EXT
echo "$ENERGYPLUS_DOWNLOAD_URL"
curl --fail -SL -C - "$ENERGYPLUS_DOWNLOAD_URL" -o "$ENERGYPLUS_DOWNLOAD_FILENAME".$EXT

# Extra downloads
EXTRAS_DOWNLOAD_URL=http://energyplus.helpserve.com/Knowledgebase/Article/GetAttachment/$ATTCHBASE/$ATTCHNUM
curl --fail -SL -C - $EXTRAS_DOWNLOAD_URL -o $ATTCHNUM.zip

# Install EnergyPlus and Extra Downloads
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  sudo chmod +x "$ENERGYPLUS_DOWNLOAD_FILENAME".$EXT
  printf "y\r" | sudo ./"$ENERGYPLUS_DOWNLOAD_FILENAME".$EXT
  sudo tar zxvf $ATTCHNUM.zip -C /usr/local/EnergyPlus-"$ENERGYPLUS_INSTALL_VERSION"/PreProcess/IDFVersionUpdater
  sudo chmod -R a+rwx /usr/local/EnergyPlus-"$ENERGYPLUS_INSTALL_VERSION"/PreProcess/IDFVersionUpdater
  sudo chmod -R a+rwx /usr/local/EnergyPlus-"$ENERGYPLUS_INSTALL_VERSION"/ExampleFiles
  # cleanup
  sudo rm $ENERGYPLUS_DOWNLOAD_FILENAME.$EXT
  sudo rm $ATTCHNUM.zip
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # getting custom install script https://github.com/NREL/EnergyPlus/pull/7615
  curl -SL -C - https://raw.githubusercontent.com/NREL/EnergyPlus/develop/cmake/qtifw/install_script.qs -o install_script.qs
  open "$ENERGYPLUS_DOWNLOAD_FILENAME".$EXT
  sudo /Volumes/$ENERGYPLUS_DOWNLOAD_FILENAME/$ENERGYPLUS_DOWNLOAD_FILENAME.app/Contents/MacOS/$ENERGYPLUS_DOWNLOAD_FILENAME --verbose --script install_script.qs Documentation=false ExampleFiles=false WeatherData=false Datasets=false Symlinks=false
  sudo tar zxvf $ATTCHNUM.zip -C /Applications/EnergyPlus-"$ENERGYPLUS_INSTALL_VERSION"/PreProcess
  sudo chmod -R a+rwx /Applications/EnergyPlus-"$ENERGYPLUS_INSTALL_VERSION"/PreProcess/IDFVersionUpdater
  sudo chmod -R a+rwx /Applications/EnergyPlus-"$ENERGYPLUS_INSTALL_VERSION"/ExampleFiles
  # cleanup
  sudo rm install_script.qs
  sudo rm $ENERGYPLUS_DOWNLOAD_FILENAME.$EXT
  sudo rm $ATTCHNUM.zip
elif [[ "$OSTYPE" == "win"* || "$OSTYPE" == "msys"* ]]; then
  powershell wget https://raw.githubusercontent.com/NREL/EnergyPlus/develop/cmake/qtifw/install_script.qs -OutFile install_script.qs
  
  # Install EnergyPlus
  $ENERGYPLUS_DOWNLOAD_FILENAME.$EXT --verbose --script install_script.qs Documentation=false ExampleFiles=false WeatherData=false Datasets=false CreateStartMenu=false RegisterFileType=false
  
  # extract extra downloads to destination
  DEST=C:\\EnergyPlusV"$ENERGYPLUS_INSTALL_VERSION"\\PreProcess\\IDFVersionUpdater
  echo "Extracting and Copying files to... $DEST"
  powershell Expand-Archive -Path $ATTCHNUM.zip -DestinationPath "$DEST" -Force

  # cleanup
  rm -v $ENERGYPLUS_DOWNLOAD_FILENAME.$EXT
  rm -v $ATTCHNUM.zip
  IDD=C:\\EnergyPlusV"$ENERGYPLUS_INSTALL_VERSION"\\Energy+.idd
  if [ -f "$IDD" ]; then
    echo "$IDD" exists
  else
    echo "$IDD" does not exist
    travis_terminate 1
  fi
fi
