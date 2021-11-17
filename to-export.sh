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
  root="$(echo "${root}" | sed 's/[^/]*\//..\//g')"
  escape "${root}"
}

grep 'raw.githubusercontent.com' -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/(https:\/\/)?raw.githubusercontent.com\/networkservicemesh\/deployments-k8s\/[a-z0-9]*\/(.*)/${root}\2/g" "${file}"
done

grep 'ref=f4cdd1e09c9701b86646eb8058139a247d200a86' -rl examples/* | while IFS= read -r file; do
  root="$(get_root "$file")"
  sedi -E "s/(https:\/\/)?github.com\/networkservicemesh\/deployments-k8s\/(.*)\?ref=f4cdd1e09c9701b86646eb8058139a247d200a86[a-z0-9]*/${root}\2/g" "${file}"
done
