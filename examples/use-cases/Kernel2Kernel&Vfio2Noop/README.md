# Test kernel to kernel connection and VFIO connection

This example shows that local kernel connection and VFIO connection can be setup by NSM at the same time.

## Run

Create test namespace:
```bash
kubectl create ns ns-kernel2kernel-vfio2noop
```

Generate MAC addresses for the VFIO client and server:
```bash
function mac_create(){
    echo -n 00
    dd bs=1 count=5 if=/dev/random 2>/dev/null | hexdump -v -e '/1 ":%02x"'
}
```
```bash
CLIENT_MAC=$(mac_create)
echo Client MAC: ${CLIENT_MAC}
```
```bash
SERVER_MAC=$(mac_create)
echo Server MAC: ${SERVER_MAC}
```

Create NSE-vfio patch:
```bash
cat > patch-nse-vfio.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-vfio
spec:
  template:
    spec:
      containers:
        - name: sidecar
          env:
            - name: NSM_SERVICES
              value: "pingpong@worker.domain: { addr: ${SERVER_MAC} }"
        - name: ponger
          command: ["/bin/bash", "/root/scripts/pong.sh", "ens6f3", "31", ${SERVER_MAC}]
EOF
```

Deploy NSCs and NSEs:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2Kernel&Vfio2Noop?ref=6722d9c0a78eda49e147e2c27581f287af037598
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-kernel2kernel-vfio2noop
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2kernel-vfio2noop
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-vfio -n ns-kernel2kernel-vfio2noop
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-vfio -n ns-kernel2kernel-vfio2noop
```

Find NSC and NSE pods by labels:
```bash
NSC_KERNEL=$(kubectl get pods -l app=nsc-kernel -n ns-kernel2kernel-vfio2noop --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE_KERNEL=$(kubectl get pods -l app=nse-kernel -n ns-kernel2kernel-vfio2noop --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSC_VFIO=$(kubectl get pods -l app=nsc-vfio -n ns-kernel2kernel-vfio2noop --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Prepare VFIO ping function:
```bash
function dpdk_ping() {
  err_file="$(mktemp)"
  trap 'rm -f "${err_file}"' RETURN

  client_mac="$1"
  server_mac="$2"

  command="/root/dpdk-pingpong/build/app/pingpong \
      --no-huge                                   \
      --                                          \
      -n 500                                      \
      -c                                          \
      -C ${client_mac}                            \
      -S ${server_mac}
      "
  out="$(kubectl -n ns-kernel2kernel-vfio2noop exec ${NSC_VFIO} --container pinger -- /bin/bash -c "${command}" 2>"${err_file}")"

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
kubectl exec ${NSC_KERNEL} -n ns-kernel2kernel-vfio2noop -- ping -c 4 172.16.1.100
```

Ping from kernel NSE to kernel NSC:
```bash
kubectl exec ${NSE_KERNEL} -n ns-kernel2kernel-vfio2noop -- ping -c 4 172.16.1.101
```

Ping from VFIO NSC to VFIO NSE:
```bash
dpdk_ping ${CLIENT_MAC} ${SERVER_MAC}
```

## Cleanup

Stop ponger:
```bash
NSE_VFIO=$(kubectl get pods -l app=nse-vfio -n ns-kernel2kernel-vfio2noop --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
kubectl -n ns-kernel2kernel-vfio2noop exec ${NSE_VFIO} --container ponger -- /bin/bash -c '\
  sleep 10 && kill $(pgrep "pingpong") 1>/dev/null 2>&1 &                    \
'
```

Delete ns:
```bash
kubectl delete ns ns-kernel2kernel-vfio2noop
```
