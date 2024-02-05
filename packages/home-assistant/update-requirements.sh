#!/usr/bin/env bash
set -xeuo pipefail
version=2024.6.3
requirements=(
  "https://raw.githubusercontent.com/home-assistant/core/$version/requirements_all.txt"
  "https://raw.githubusercontent.com/home-assistant/core/$version/requirements.txt"
)
constraints=(
  "https://raw.githubusercontent.com/home-assistant/core/$version/homeassistant/package_constraints.txt"
)
curl "${requirements[@]}" | sed -e '/^[ \t]*#/d;/^-r/d;/^-c/d;/^[[:space:]]*$/d' | sort -u >./requirements.txt
curl "${constraints[@]}" | sed -e '/^[ \t]*#/d;/^[[:space:]]*$/d' | sort -u > ./package_constraints.txt
