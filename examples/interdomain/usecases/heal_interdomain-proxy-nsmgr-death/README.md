# Proxy nsmgrs death in interdomain scenario

This example shows that NSM keeps working after NSM proxy-managers on the first and the second cluster are deleted.

NSC and NSE use the `kernel` mechanism to connect to their local forwarders.
Forwarders from the first and the second cluster use the `vxlan` mechanism to connect to each other.

NSE registers itself and its Network Service in the local registry on the second cluster.


## Requires

Make sure that you have completed steps from [heal](../../suites/heal)

## Run

**1. Deploy endpoint on cluster2**

Deploy NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/heal_interdomain-proxy-nsmgr-death/cluster2?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-interdomain-proxy-nsmgr-death
```

**2. Deploy client on cluster1**

Deploy NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k https://github.com/networkservicemesh/deployments-k8s/examples/interdomain/usecases/heal_interdomain-proxy-nsmgr-death/cluster1?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=alpine -n ns-interdomain-proxy-nsmgr-death
```

**3. Check connectivity**

Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-interdomain-proxy-nsmgr-death -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-interdomain-proxy-nsmgr-death -- ping -c 4 172.16.1.3
```

**4. Find proxy-nsmgr on both clusters**

```bash
LOCAL_PROXY_NSMGR=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=nsmgr-proxy -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
REMOTE_PROXY_NSMGR=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=nsmgr-proxy -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

**5. Delete proxy-nsmgrs**

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete pod ${LOCAL_PROXY_NSMGR} -n nsm-system
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 delete pod ${REMOTE_PROXY_NSMGR} -n nsm-system
```

**6. Wait until new proxy-nsmgrs are ready**

```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=1m pod -l app=nsmgr-proxy -n nsm-system
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=1m pod -l app=nsmgr-proxy -n nsm-system
```

**7. Check connectivity with newly created proxy-nsmgrs**

Ping from NSC to NSE:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec pods/alpine -n ns-interdomain-proxy-nsmgr-death -- ping -c 4 172.16.1.2
```

Ping from NSE to NSC:
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec deployments/nse-kernel -n ns-interdomain-proxy-nsmgr-death -- ping -c 4 172.16.1.3
```


## Cleanup

Cleanup resources for *cluster1*:
```bash
kubectl --kubeconfig=$KUBECONFIG1 delete ns ns-interdomain-proxy-nsmgr-death
```

Cleanup resources for *cluster2*:
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete ns ns-interdomain-proxy-nsmgr-death
```
