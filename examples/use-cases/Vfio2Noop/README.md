# Test VFIO connection

This example shows that NSC and NSE can work with each other over the VFIO connection.

## Requires

Make sure that you have completed steps from [sriov](../../sriov) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a/examples/use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
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
          command: ["/bin/bash", "/root/scripts/pong.sh", "eno4", "31", ${SERVER_MAC}]
EOF
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-vfio?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-vfio?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a

patchesStrategicMerge:
- patch-nse-vfio.yaml
EOF
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl -n ${NAMESPACE} wait --for=condition=ready --timeout=1m pod -l app=nsc-vfio
```
```bash
kubectl -n ${NAMESPACE} wait --for=condition=ready --timeout=1m pod -l app=nse-vfio
```

Get NSC pod:
```bash
NSC_VFIO=$(kubectl -n ${NAMESPACE} get pods -l app=nsc-vfio --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Check connectivity:
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
```bash
dpdk_ping ${CLIENT_MAC} ${SERVER_MAC}
```

## Cleanup

Stop ponger:
```bash
NSE=$(kubectl -n ${NAMESPACE} get pods -l app=nse-vfio --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
kubectl -n ${NAMESPACE} exec ${NSE} --container ponger -- /bin/bash -c '\
  sleep 10 && kill $(pgrep "pingpong") 1>/dev/null 2>&1 &               \
'
```

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
