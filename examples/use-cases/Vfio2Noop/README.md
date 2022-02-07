# Test VFIO connection

This example shows that NSC and NSE can work with each other over the VFIO connection.

## Requires

Make sure that you have completed steps from [sriov](../../sriov) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/use-cases/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-vfio?ref=da0228654084085b3659ed6b519f66f44b6796ce
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-vfio?ref=da0228654084085b3659ed6b519f66f44b6796ce
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
NSC=$(kubectl -n ${NAMESPACE} get pods -l app=nsc-vfio --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Check connectivity:
```bash
function dpdk_ping() {
  err_file="$(mktemp)"
  trap 'rm -f "${err_file}"' RETURN

  out="$(kubectl -n ${NAMESPACE} exec ${NSC} --container pinger -- /bin/bash -c '\
    /root/dpdk-pingpong/build/app/pingpong                                       \
      --no-huge                                                                  \
      --                                                                         \
      -n 500                                                                     \
      -c                                                                         \
      -C 0a:11:22:33:44:55                                                       \
      -S 0a:55:44:33:22:11                                                       \
  ' 2>"${err_file}")"

  if [[ "$?" != 0 ]]; then
    cat "${err_file}" 1>&2
    echo "${out}" 1>&2
    return 1
  fi

  if ! pong_packets="$(echo "${out}" | grep "rx .* pong packets" | sed -E 's/rx ([0-9]*) pong packets/\1/g')"; then
    cat "${err_file}" 1>&2
    echo "${out}" 1>&2
    return 1
  fi

  if [[ "${pong_packets}" == 0 ]]; then
    cat "${err_file}" 1>&2
    echo "${out}" 1>&2
    return 1
  fi

  echo "${out}"
  return 0
}
```
```bash
dpdk_ping
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
