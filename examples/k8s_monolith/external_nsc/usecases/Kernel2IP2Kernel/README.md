# Test kernel to IP to kernel connection

Docker-NSC and NSE are using the `kernel` local mechanism.
`Wireguard` is used as remote mechanism.

## Requires

Make sure that you have completed steps from [external NSC](../../)

## Run

Deploy NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/k8s_monolith/external_nsc/usecases/Kernel2IP2Kernel?ref=a67c03c99d4f1ccb060c1f2a57421256af2333e1
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-kernel2ip2kernel-monolith-nsc
```

Ping from docker-NSC to NSE:
```bash
docker exec nsc-simple-docker ping -c4 172.16.1.100
```

Ping from NSE to docker-NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-kernel2ip2kernel-monolith-nsc -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:

```bash
kubectl delete ns ns-kernel2ip2kernel-monolith-nsc
```
