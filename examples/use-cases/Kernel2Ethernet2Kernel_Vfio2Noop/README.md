# Test kernel to Ethernet to kernel connection and VFIO connection

This example shows that remote kernel over Ethernet connection and VFIO connection can be setup by NSM at the same time.

## Run

Deploy NSCs and NSEs:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2Ethernet2Kernel_Vfio2Noop?ref=c6d92f4d1102a71e28f37f9fc0d6d3b1edbeba66
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-kernel2ethernet2kernel-vfio2noop
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2ethernet2kernel-vfio2noop
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-vfio -n ns-kernel2ethernet2kernel-vfio2noop
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-vfio -n ns-kernel2ethernet2kernel-vfio2noop
```

Prepare VFIO ping function:
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
  out="$(kubectl -n ns-kernel2ethernet2kernel-vfio2noop exec deployments/nsc-vfio --container pinger -- /bin/bash -c "${command}" 2>"${err_file}")"

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

Ping from kernel NSC to kernel NSE:
```bash
kubectl exec pods/alpine -n ns-kernel2ethernet2kernel-vfio2noop -- ping -c 4 172.16.1.100
```

Ping from kernel NSE to kernel NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2ethernet2kernel-vfio2noop -- ping -c 4 172.16.1.101
```

Ping from VFIO NSC to VFIO NSE:
```bash
dpdk_ping "0a:55:44:33:22:00" "0a:55:44:33:22:11"
```

## Cleanup

Stop ponger:
```bash
kubectl -n ns-kernel2ethernet2kernel-vfio2noop exec deployments/nse-vfio --container ponger -- /bin/bash -c '\
  (sleep 10 && kill $(pgrep "pingpong")) 1>/dev/null 2>&1 &                    \
'
```

Delete ns:
```bash
kubectl delete ns ns-kernel2ethernet2kernel-vfio2noop
```
