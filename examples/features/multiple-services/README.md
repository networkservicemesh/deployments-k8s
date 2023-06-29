# Test NSC connects to multiple Network Services

This example shows that NSC can connect to multiple Network Services at the same time.

In this example there are two different Network Services which are implemented by two NSEs.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [ipsec mechanism](../../ipsec_mechanism) setup.

## Run

Deploy NSC and and two NSEs:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/multiple-services?ref=3f98f0059571701a0c9bedd20efe3605373507a1
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=alpine -n ns-multiple-services
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-1 -n ns-multiple-services
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-2 -n ns-multiple-services
```

Ping from NSC to the first NSE:
```bash
kubectl exec pods/alpine -n ns-multiple-services -- ping -c 4 172.16.1.100
```

Ping from the first NSE to NSC:
```bash
kubectl exec pods/nse-kernel-1 -n ns-multiple-services -- ping -c 4 172.16.1.101
```

Ping from NSC to the second NSE:
```bash
kubectl exec pods/alpine -n ns-multiple-services -- ping -c 4 172.16.2.100
```

Ping from the second NSE to NSC:
```bash
kubectl exec pods/nse-kernel-2 -n ns-multiple-services -- ping -c 4 172.16.2.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-multiple-services
```
