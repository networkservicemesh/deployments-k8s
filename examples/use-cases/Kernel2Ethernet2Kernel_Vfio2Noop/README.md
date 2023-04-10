# Test kernel to Ethernet to kernel connection and VFIO connection

This example shows that remote kernel over Ethernet connection and VFIO connection can be setup by NSM at the same time.

## Run

Deploy NSCs and NSEs:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2Ethernet2Kernel_Vfio2Noop?ref=23c31c3f988560a168e7f7af46f4edc8ad27964d
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

Find NSC and NSE pods by labels:
```bash
NSC_KERNEL=$(kubectl get pods -l app=alpine -n ns-kernel2ethernet2kernel-vfio2noop --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE_KERNEL=$(kubectl get pods -l app=nse-kernel -n ns-kernel2ethernet2kernel-vfio2noop --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSC_VFIO=$(kubectl get pods -l app=nsc-vfio -n ns-kernel2ethernet2kernel-vfio2noop --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
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
  out="$(kubectl -n ns-kernel2ethernet2kernel-vfio2noop exec ${NSC_VFIO} --container pinger -- /bin/bash -c "${command}" 2>"${err_file}")"

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
kubectl exec ${NSC_KERNEL} -n ns-kernel2ethernet2kernel-vfio2noop -- ping -c 4 172.16.1.100
```

Ping from kernel NSE to kernel NSC:
```bash
kubectl exec ${NSE_KERNEL} -n ns-kernel2ethernet2kernel-vfio2noop -- ping -c 4 172.16.1.101
```

Ping from VFIO NSC to VFIO NSE:
```bash
dpdk_ping "0a:55:44:33:22:00" "0a:55:44:33:22:11"
```

## Cleanup

Stop ponger:
```bash
NSE_VFIO=$(kubectl get pods -l app=nse-vfio -n ns-kernel2ethernet2kernel-vfio2noop --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
kubectl -n ns-kernel2ethernet2kernel-vfio2noop exec ${NSE_VFIO} --container ponger -- /bin/bash -c '\
  (sleep 10 && kill $(pgrep "pingpong")) 1>/dev/null 2>&1 &                    \
'
```

Delete ns:
```bash
kubectl delete ns ns-kernel2ethernet2kernel-vfio2noop
```
