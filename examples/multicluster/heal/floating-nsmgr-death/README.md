# Floating interdomain NSE death example

This example shows that NSC can reach NSE registered in floating registry.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

NSE is registering in the floating registry.


## Requires

Make sure that you have completed steps from [multicluster](../../)

## Run

**1. Deploy network service on cluster3**

Deploy NS:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -k ../../../../../../../../../../home/nikita/repos/NSM/deployments-k8s/examples/multicluster/heal/floating-nsmgr-death/cluster3
```

**2. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k ../../../../../../../../../../home/nikita/repos/NSM/deployments-k8s/examples/multicluster/heal/floating-nsmgr-death/cluster2
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-floating-nsmgr-death
```

**3. Deploy client on cluster1**

Deploy NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ../../../../../../../../../../home/nikita/repos/NSM/deployments-k8s/examples/multicluster/heal/floating-nsmgr-death/cluster1
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-floating-nsmgr-death
```

**3. Check connectivity**

Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-floating-nsmgr-death -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-floating-nsmgr-death -- ping -c 4 172.16.1.3
```

```bash
LOCALNSMGR=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=nsmgr -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
REMOTENSMGR=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=nsmgr -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete pod ${LOCALNSMGR} -n nsm-system
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 delete pod ${REMOTENSMGR} -n nsm-system
```

```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=1m pod -l app=nsmgr -n nsm-system
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nsmgr -n nsm-system
```

Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-floating-nsmgr-death -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-floating-nsmgr-death -- ping -c 4 172.16.1.3
```


## Cleanup

Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-floating-nsmgr-death
```

Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-floating-nsmgr-death
```

3. Cleanup resources for *cluster3*:
```bash
kubectl --kubeconfig=$KUBECONFIG3 delete ns ns-floating-nsmgr-death
```
