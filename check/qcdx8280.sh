#!/bin/bash

grep_ver() {
    curl -s "$1" | grep "qcdx8280.cab" | awk '{last=$0} END {print $2}'
}

echo -n "8280_QRD: "
grep_ver https://raw.githubusercontent.com/WOA-Project/Qualcomm-Reference-Drivers/refs/heads/master/8280_QRD/CHANGELOG.md

echo -n "8280_ARC: "
grep_ver https://raw.githubusercontent.com/WOA-Project/Qualcomm-Reference-Drivers/refs/heads/master/Surface/8280_ARC_1997/CHANGELOG.md
