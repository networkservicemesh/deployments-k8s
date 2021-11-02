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

grep 'raw.githubusercontent.com' -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/(https:\/\/)?raw.githubusercontent.com\/networkservicemesh\/deployments-k8s\/[a-z0-9]*\/(.*)/${root}\/\2/g" "${file}"
done

grep 'ref=88506ec9fd39e001fbc96c89921a8b74f8803988' -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/(https:\/\/)?github.com\/networkservicemesh\/deployments-k8s\/(.*)\?ref=88506ec9fd39e001fbc96c89921a8b74f8803988[a-z0-9]*/${root}\/\2/g" "${file}"
done
