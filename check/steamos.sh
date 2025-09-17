#!/bin/bash
curl -s "https://steamdeck-images.steamos.cloud/steamdeck/?C=M&O=D" |
    hxclean |
    hxselect 'tr:nth-of-type(2) a' |
    hxpipe |
    grep '^Atitle' |
    awk '{print $3}'
