# Floating interdomain kernel to ethernet to kernel example

This example shows that NSC can reach NSE registered in floating registry.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

NSE is registering in the floating registry.


## Requires

Make sure that you have completed steps from [multicluster-heal](../../)

## Run

**1. Deploy network service on cluster3**

Deploy NS:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster-heal/usecases/floating-nse-death/cluster3?ref=b7a0736c9257da4c7e0880b8338f254f94097d4c
```

**2. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster-heal/usecases/floating-nse-death/cluster2?ref=b7a0736c9257da4c7e0880b8338f254f94097d4c
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-floating-nse-death
```

**3. Deploy client on cluster1**

Deploy NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/multicluster-heal/usecases/floating-nse-death/cluster1?ref=b7a0736c9257da4c7e0880b8338f254f94097d4c
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-floating-nse-death
```

**3. Check connectivity**

Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-floating-nse-death -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-floating-nse-death -- ping -c 4 172.16.1.3
```

**4. Delete NSE**
```bash
NSE=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=nse-kernel -n ns-floating-nse-death --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 delete pod ${NSE} -n ns-floating-nse-death
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-floating-nse-death
```

**5. Check connectivity for a new NSE**
Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-floating-nse-death -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-floating-nse-death -- ping -c 4 172.16.1.3
```

## Cleanup

Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-floating-nse-death
```

Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-floating-nse-death
```

3. Cleanup resources for *cluster3*:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns ns-floating-nse-death
```
