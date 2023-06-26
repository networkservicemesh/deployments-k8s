# Test NSE composition

This example demonstrates a more complex Network Service, where we chain three passthrough and one ACL Filtering NS endpoints.
It demonstrates how NSM allows for service composition (chaining).
It involves a combination of kernel and memif mechanisms, as well as VPP enabled endpoints.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/nse-composition?ref=1d0872db3439487792362cd0a81c4c415659dfd6
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-nse-composition
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-nse-composition
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-nse-composition -- ping -c 4 172.16.1.100
```

Check TCP Port 8080 on NSE is accessible to NSC
```bash
kubectl exec pods/alpine -n ns-nse-composition -- wget -O /dev/null --timeout 5 "172.16.1.100:8080"
```

Check TCP Port 80 on NSE is inaccessible to NSC
```bash
kubectl exec pods/alpine -n ns-nse-composition -- wget -O /dev/null --timeout 5 "172.16.1.100:80"
if [ 0 -eq $? ]; then
  echo "error: port :80 is available" >&2
  false
else
  echo "success: port :80 is unavailable"
fi
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-nse-composition -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-nse-composition
```
