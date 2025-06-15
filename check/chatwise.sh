#!/bin/bash
curl -s https://chatwise.app/api/trpc/getReleases |
    jq -r '[ .result.data[] ] | reverse[] | "Version: \(.name)\nTime: \(.publishedAt | fromdate | strftime("%Y-%m-%d %H:%M:%S"))\nChangelog:\n\(.body)\n---"'
