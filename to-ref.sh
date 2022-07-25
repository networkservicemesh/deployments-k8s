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

FILE_PATTERN="$(escape 'https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/68ab058dd8e69ee08a358df046a5a6645db84475/\1')"
grep "$(pwd)" -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/${root//./\.}\/([^ ]*\.[a-z]+)/${FILE_PATTERN}/g" "${file}"
done

DIR_PATTERN="$(escape 'https://github.com/networkservicemesh/deployments-k8s/\1?ref=68ab058dd8e69ee08a358df046a5a6645db84475')"
grep "$(pwd)" -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/${root//./\.}\/([^ ]*)/${DIR_PATTERN}/g" "${file}"
done
