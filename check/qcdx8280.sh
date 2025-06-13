#!/bin/sh
curl -s https://raw.githubusercontent.com/WOA-Project/Qualcomm-Reference-Drivers/refs/heads/master/8280_QRD/CHANGELOG.md | grep "qcdx8280.cab" | awk '{last=$0} END {print $2}'
