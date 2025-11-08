#/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
PS_SCRIPT="$SCRIPT_DIR/SwitchTorch.ps1"

powershell.exe $PS_SCRIPT "$@"
