# Test Mutually Aware NSEs

This example demonstrates mutually aware NSEs usage.

Mutually aware NSEs are allowed to have overlapping IP spaces.

Based on Policy Based Routing example.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/mutually-aware-nses?ref=a98f08d26c1354b0b6cc1835c2f5f4bb5c4e33e3
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-mutually-aware-nses
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-1 -n ns-mutually-aware-nses
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-2 -n ns-mutually-aware-nses
```

Install `iproute2` on the client:
```bash
kubectl exec deployments/nsc-kernel -n ns-mutually-aware-nses -- apk update
kubectl exec deployments/nsc-kernel -n ns-mutually-aware-nses -- apk add iproute2
```

Check routes:
```bash
result=$(kubectl exec deployments/nsc-kernel -n ns-mutually-aware-nses -- ip r get 172.16.1.100 from 172.16.1.101 ipproto tcp dport 6666)
echo ${result}
echo ${result} | grep -E -q "172.16.1.100 from 172.16.1.101 dev nsm-1"
```

```bash
result=$(kubectl exec deployments/nsc-kernel -n ns-mutually-aware-nses -- ip r get 172.16.1.100 from 172.16.1.101 ipproto udp dport 5555)
echo ${result}
echo ${result} | grep -E -q "172.16.1.100 from 172.16.1.101 dev nsm-2"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-mutually-aware-nses
```
