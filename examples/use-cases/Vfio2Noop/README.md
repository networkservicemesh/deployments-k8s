# Test VFIO connection

This example shows that NSC and NSE can work with each other over the VFIO connection.

## Requires

Make sure that you have completed steps from [sriov](../../sriov) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Vfio2Noop?ref=a689574a07e038d3b86ff777a9429feaba33c6ab
```

Wait for applications ready:
```bash
kubectl -n ns-vfio2noop wait --for=condition=ready --timeout=1m pod -l app=nsc-vfio
```
```bash
kubectl -n ns-vfio2noop wait --for=condition=ready --timeout=1m pod -l app=nse-vfio
```

Check connectivity:
```bash
function dpdk_ping() {
  err_file="$(mktemp)"
  trap 'rm -f "${err_file}"' RETURN

  client_mac="$1"
  server_mac="$2"

  command="/root/dpdk-pingpong/build/pingpong \
      --no-huge                               \
      --                                      \
      -n 500                                  \
      -c                                      \
      -C ${client_mac}                        \
      -S ${server_mac}
      "
  out="$(kubectl -n ns-vfio2noop exec deployments/nsc-vfio --container pinger -- /bin/bash -c "${command}" 2>"${err_file}")"

  if [[ "$?" != 0 ]]; then
    echo "${out}"
    cat "${err_file}" 1>&2
    return 1
  fi

  if ! pong_packets="$(echo "${out}" | grep "rx .* pong packets" | sed -E 's/rx ([0-9]*) pong packets/\1/g')"; then
    echo "${out}"
    cat "${err_file}" 1>&2
    return 1
  fi

  if [[ "${pong_packets}" == 0 ]]; then
    echo "${out}"
    cat "${err_file}" 1>&2
    return 1
  fi

  echo "${out}"
  return 0
}
```

Ping with client and server MAC addresses:
```bash
dpdk_ping "0a:55:44:33:22:00" "0a:55:44:33:22:11"
```

## Cleanup

Stop ponger:
```bash
kubectl -n ns-vfio2noop exec deployments/nse-vfio --container ponger -- /bin/bash -c '\
  (sleep 10 && kill $(pgrep "pingpong")) 1>/dev/null 2>&1 &             \
'
```

Delete ns:
```bash
kubectl delete ns ns-vfio2noop
```
