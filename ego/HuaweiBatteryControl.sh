#/bin/sh

SCRIPT_DIR=$(dirname "$(realpath "$0")")
PS_SCRIPT="$SCRIPT_DIR/HuaweiBatteryControl.ps1"

sudo.exe powershell.exe $PS_SCRIPT "$@"