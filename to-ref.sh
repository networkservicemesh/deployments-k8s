#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  sedi() { sed -i "" "$@"; }
else
  sedi() { sed -i "$@"; }
fi

escape() {
  echo "$1" | sed 's/\//\\\//g'
}

get_root() {
  root="$(echo "$1" | sed 's/[^/]*$//g')"
  root="$(echo "$(pwd)/${root}" | sed 's/[^/]*\//..\//g')"
  root="$(echo "${root}$(pwd)" | sed 's/\/\//\//g')"
  escape "${root}"
}

FILE_PATTERN="$(escape 'https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/ec05696f19969f5d6b8bea1fa34de9358a17080b/\1')"
grep "$(pwd)" -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/${root//./\.}\/([^ ]*\.[a-z]+)/${FILE_PATTERN}/g" "${file}"
done

DIR_PATTERN="$(escape 'https://github.com/networkservicemesh/deployments-k8s/\1?ref=ec05696f19969f5d6b8bea1fa34de9358a17080b')"
grep "$(pwd)" -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/${root//./\.}\/([^ ]*)/${DIR_PATTERN}/g" "${file}"
done
