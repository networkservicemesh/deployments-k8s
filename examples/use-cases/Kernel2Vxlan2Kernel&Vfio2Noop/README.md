# Test kernel to VXLAN to kernel connection and VFIO connection

This example shows that remote kernel over VXLAN connection and VFIO connection can be setup by NSM at the same time.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a/examples/use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Select node to deploy NSC and NSE:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
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

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-vfio?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-vfio?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a

patchesStrategicMerge:
- patch-nsc.yaml
- patch-nse.yaml
- patch-nse-vfio.yaml
EOF
```

Create kernel NSC patch:
```bash
cat > patch-nsc.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsc-kernel
spec:
  template:
    spec:
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: kernel://icmp-responder/nsm-1
      nodeName: ${NODES[0]}
EOF
```

Create kernel NSE patch:
```bash
cat > patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31
      nodeName: ${NODES[1]}
EOF
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
          command: ["/bin/bash", "/root/scripts/pong.sh", "eno4", "31", ${SERVER_MAC}]
EOF
```

Deploy NSCs and NSEs:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-vfio -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-vfio -n ${NAMESPACE}
```

Find NSC and NSE pods by labels:
```bash
NSC_KERNEL=$(kubectl get pods -l app=nsc-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE_KERNEL=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSC_VFIO=$(kubectl get pods -l app=nsc-vfio -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
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
  out="$(kubectl -n ${NAMESPACE} exec ${NSC_VFIO} --container pinger -- /bin/bash -c "${command}" 2>"${err_file}")"

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
kubectl exec ${NSC_KERNEL} -n ${NAMESPACE} -- ping -c 4 172.16.1.100
```

Ping from kernel NSE to kernel NSC:
```bash
kubectl exec ${NSE_KERNEL} -n ${NAMESPACE} -- ping -c 4 172.16.1.101
```

Ping from VFIO NSC to VFIO NSE:
```bash
dpdk_ping ${CLIENT_MAC} ${SERVER_MAC}
```

## Cleanup

Stop ponger:
```bash
NSE_VFIO=$(kubectl get pods -l app=nse-vfio -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
kubectl -n ${NAMESPACE} exec ${NSE_VFIO} --container ponger -- /bin/bash -c '\
  sleep 10 && kill $(pgrep "pingpong") 1>/dev/null 2>&1 &                    \
'
```

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
