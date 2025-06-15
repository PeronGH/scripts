#!/bin/bash

curl -s https://update.greasyfork.org/scripts/539399/Google%20AI%20Studio%20%E6%A8%A1%E5%9E%8B%E6%B3%A8%E5%85%A5%E5%99%A8.user.js |
    sed -n '/const PREDEFINED_MODELS = \[/,/\];/p'
