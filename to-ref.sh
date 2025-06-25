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

FILE_PATTERN="$(escape 'https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/af13bdcc58e615ca5de72be43c5ce37641a1b665/\1')"
grep "$(pwd)" -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/${root//./\.}\/([^ ]*\.[a-z]+)/${FILE_PATTERN}/g" "${file}"
done

DIR_PATTERN="$(escape 'https://github.com/networkservicemesh/deployments-k8s/\1?ref=af13bdcc58e615ca5de72be43c5ce37641a1b665')"
grep "$(pwd)" -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/${root//./\.}\/([^ ]*)/${DIR_PATTERN}/g" "${file}"
done
