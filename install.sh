#!/bin/bash
set -euo pipefail

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Check if EnergyPlus env variables exist already. If not use these defaults
if [[ -z "${ENERGYPLUS_VERSION:-}" ]]; then
  export ENERGYPLUS_VERSION=9.2.0
fi
if [[ -z "${ENERGYPLUS_SHA:-}" ]]; then
  export ENERGYPLUS_SHA=921312fa1d
fi

# Derive install version from version (replace dots with dashes)
export ENERGYPLUS_INSTALL_VERSION="${ENERGYPLUS_VERSION//./-}"

if [[ -z "${ENERGYPLUS_TAG:-}" ]]; then
  export ENERGYPLUS_TAG="v${ENERGYPLUS_VERSION}"
fi

# Auto-detect or use provided architecture
if [[ -z "${ENERGYPLUS_ARCH:-}" ]]; then
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64|amd64)
      export ENERGYPLUS_ARCH=x86_64
      ;;
    aarch64|arm64)
      export ENERGYPLUS_ARCH=arm64
      ;;
    *)
      echo "Warning: Unknown architecture '$ARCH', defaulting to x86_64"
      export ENERGYPLUS_ARCH=x86_64
      ;;
  esac
fi

# Set OS-specific variables (extension and extras download info)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  EXT="sh"
  ATTCHBASE=67022360382
  ATTCHNUM="multipletransitionidfversionupdater-lin.tar.gz"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  EXT=dmg
  ATTCHBASE=67022360547
  ATTCHNUM="idfversionupdater-macos-v8.4.0.zip"
elif [[ "$OSTYPE" == "win"* || "$OSTYPE" == "msys"* ]]; then
  EXT=zip
  ATTCHBASE=67022360088
  ATTCHNUM="multipletransitionidfversionupdater-win.zip"
else
  echo "Error: Unsupported OS type '$OSTYPE'"
  exit 1
fi

# Auto-detect platform if not provided
if [[ -z "${ENERGYPLUS_PLATFORM:-}" ]]; then
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if version_gt "$ENERGYPLUS_VERSION" 23.1.0; then
      PLATFORM=Linux-Ubuntu22.04
    elif version_gt "$ENERGYPLUS_VERSION" 9.3.0; then
      PLATFORM=Linux-Ubuntu18.04
    else
      PLATFORM=Linux
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if version_gt "$ENERGYPLUS_VERSION" 23.1.0; then
      PLATFORM=Darwin-macOS12.1
    elif version_gt "$ENERGYPLUS_VERSION" 9.3.0; then
      PLATFORM=Darwin-macOS10.15
    else
      PLATFORM=Darwin
    fi
  elif [[ "$OSTYPE" == "win"* || "$OSTYPE" == "msys"* ]]; then
    PLATFORM=Windows
  fi
else
  PLATFORM="$ENERGYPLUS_PLATFORM"
fi

# Download EnergyPlus executable
ENERGYPLUS_DOWNLOAD_BASE_URL="https://github.com/NREL/EnergyPlus/releases/download/${ENERGYPLUS_TAG}"
ENERGYPLUS_DOWNLOAD_FILENAME="EnergyPlus-${ENERGYPLUS_VERSION}-${ENERGYPLUS_SHA}-${PLATFORM}-${ENERGYPLUS_ARCH}"
ENERGYPLUS_DOWNLOAD_URL="${ENERGYPLUS_DOWNLOAD_BASE_URL}/${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}"
echo "$ENERGYPLUS_DOWNLOAD_URL"
curl --fail -SL "$ENERGYPLUS_DOWNLOAD_URL" -o "${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}"

# Extra downloads
EXTRAS_DOWNLOAD_URL="https://energyplushelp.freshdesk.com/helpdesk/attachments/${ATTCHBASE}"
curl --fail -SL "$EXTRAS_DOWNLOAD_URL" -o "$ATTCHNUM"

# Resolve the path to the vendored install script (for macOS)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install EnergyPlus and Extra Downloads
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  sudo chmod +x "${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}"
  printf "y\r" | sudo "./${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}"
  sudo tar zxvf "$ATTCHNUM" -C "/usr/local/EnergyPlus-${ENERGYPLUS_INSTALL_VERSION}/PreProcess/IDFVersionUpdater"
  sudo chmod -R a+rwx "/usr/local/EnergyPlus-${ENERGYPLUS_INSTALL_VERSION}/PreProcess/IDFVersionUpdater"
  sudo chmod -R a+rwx "/usr/local/EnergyPlus-${ENERGYPLUS_INSTALL_VERSION}/ExampleFiles"

  # Verify installation
  IDD="/usr/local/EnergyPlus-${ENERGYPLUS_INSTALL_VERSION}/Energy+.idd"
  if [ -f "$IDD" ]; then
    echo "$IDD exists"
  else
    echo "Error: $IDD does not exist — installation may have failed"
    exit 1
  fi

  # Cleanup
  sudo rm "${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}"
  sudo rm "$ATTCHNUM"

elif [[ "$OSTYPE" == "darwin"* ]]; then
  # Use vendored install script
  INSTALL_SCRIPT="${SCRIPT_DIR}/scripts/install_script.qs"
  sudo hdiutil attach "${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}"
  sudo "/Volumes/${ENERGYPLUS_DOWNLOAD_FILENAME}/${ENERGYPLUS_DOWNLOAD_FILENAME}.app/Contents/MacOS/${ENERGYPLUS_DOWNLOAD_FILENAME}" --verbose --script "$INSTALL_SCRIPT"
  sudo tar zxvf "$ATTCHNUM" -C "/Applications/EnergyPlus-${ENERGYPLUS_INSTALL_VERSION}/PreProcess"
  sudo chmod -R a+rwx "/Applications/EnergyPlus-${ENERGYPLUS_INSTALL_VERSION}/PreProcess/IDFVersionUpdater"
  sudo chmod -R a+rwx "/Applications/EnergyPlus-${ENERGYPLUS_INSTALL_VERSION}/ExampleFiles"

  # Verify installation
  IDD="/Applications/EnergyPlus-${ENERGYPLUS_INSTALL_VERSION}/Energy+.idd"
  if [ -f "$IDD" ]; then
    echo "$IDD exists"
  else
    echo "Error: $IDD does not exist — installation may have failed"
    exit 1
  fi

  # Cleanup
  sudo rm "${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}"
  sudo rm "$ATTCHNUM"

elif [[ "$OSTYPE" == "win"* || "$OSTYPE" == "msys"* ]]; then
  echo "Extracting and Copying files to... C:\\"
  powershell Expand-Archive -Path "${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}" -DestinationPath C:\\
  powershell Rename-Item -Path "c:\\${ENERGYPLUS_DOWNLOAD_FILENAME}" -NewName "EnergyPlusV${ENERGYPLUS_INSTALL_VERSION}"

  # Extract extra downloads to destination
  DEST="C:\\EnergyPlusV${ENERGYPLUS_INSTALL_VERSION}\\PreProcess\\IDFVersionUpdater"
  echo "Extracting and Copying files to... $DEST"
  powershell Expand-Archive -Path "$ATTCHNUM" -DestinationPath "$DEST" -Force

  # Cleanup
  rm -v "${ENERGYPLUS_DOWNLOAD_FILENAME}.${EXT}"
  rm -v "$ATTCHNUM"

  # Verify installation
  IDD="C:\\EnergyPlusV${ENERGYPLUS_INSTALL_VERSION}\\Energy+.idd"
  if [ -f "$IDD" ]; then
    echo "$IDD exists"
  else
    echo "Error: $IDD does not exist — installation may have failed"
    exit 1
  fi
fi
