# Test kernel to wireguard to kernel connection

Docker-NSC and NSE are using the `kernel` local mechanism.
`Wireguard` is used as remote mechanism.

## Requires

Make sure that you have completed steps from [external NSC](../../)

## Run

Deploy NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/k8s_monolith/external_nsc/usecases/Kernel2Wireguard2Kernel?ref=03195ce79ddcae37aa2239be05cc8a13bbc71ecb
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2wireguard2kernel-monolith-nsc
```

Find NSE pod by label:
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-kernel2wireguard2kernel-monolith-nsc --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from docker-NSC to NSE:
```bash
docker exec nsc-simple-docker ping -c4 172.16.1.100
```

Ping from NSE to docker-NSC:
```bash
kubectl exec ${NSE} -n ns-kernel2wireguard2kernel-monolith-nsc -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:

```bash
kubectl delete ns ns-kernel2wireguard2kernel-monolith-nsc
```
