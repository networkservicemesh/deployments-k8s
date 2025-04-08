# Forwarders death in floating interdomain scenario

This example shows that NSM keeps working after forwarders on the first and the second clusters are deleted.

NSC and NSE use the `kernel` mechanism to connect to their local forwarders.
Forwarders from the first and the second cluster use the `vxlan` mechanism to connect to each other.

NSE registers itself in the floating registry.

## Requires

Make sure that you have completed steps from [heal](../../suites/heal)

## Run

**1. Deploy network service on cluster3**

Deploy NS:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/heal_floating-forwarder-death/cluster3?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

**2. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/heal_floating-forwarder-death/cluster2?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-floating-forwarder-death
```

**3. Deploy client on cluster1**

Deploy NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/heal_floating-forwarder-death/cluster1?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-floating-forwarder-death
```

**4. Check connectivity**

Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-floating-forwarder-death -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-floating-forwarder-death -- ping -c 4 172.16.1.3
```

**5. Find forwarders on the first and the second clusters**

```bash
LOCALFWD=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=forwarder-vpp -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
REMOTEFWD=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=forwarder-vpp -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

**6. Delete forwarders from both clusters**

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete pod ${LOCALFWD} -n nsm-system
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 delete pod ${REMOTEFWD} -n nsm-system
```

**7. Wait until newly created forwarders are ready**

```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp -n nsm-system
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=forwarder-vpp -n nsm-system
```

**8. Check connectivity with newly created forwarders**

Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-floating-forwarder-death -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-floating-forwarder-death -- ping -c 4 172.16.1.3
```


## Cleanup

Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-floating-forwarder-death
```

Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-floating-forwarder-death
```

3. Cleanup resources for *cluster3*:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns ns-floating-forwarder-death
```
