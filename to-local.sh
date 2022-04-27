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

grep 'ref=8eec83a534bed510d05a6b5f25bd347dcfd81a6d' -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/(https:\/\/)?github.com\/networkservicemesh\/deployments-k8s\/(.*)\?ref=8eec83a534bed510d05a6b5f25bd347dcfd81a6d[a-z0-9]*/${root}\/\2/g" "${file}"
done
