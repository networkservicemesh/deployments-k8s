# SPIRE upgrade

This example shows that NSM keeps working after the SPIRE deployment removed and re-installed.

NSC and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
kubectl create ns ns-spire-upgrade
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/spire-upgrade?ref=c340ebd0c2ba2d43a9b162268a3606d017cd31e9
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ns-spire-upgrade
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ns-spire-upgrade
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-spire-upgrade -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-spire-upgrade -- ping -c 4 172.16.1.101
```

Remove SPIRE deployment completely:
```bash
kubectl delete crd clusterspiffeids.spire.spiffe.io
kubectl delete crd clusterfederatedtrustdomains.spire.spiffe.io
kubectl delete validatingwebhookconfiguration.admissionregistration.k8s.io/spire-controller-manager-webhook
kubectl delete ns spire
```

Deploy SPIRE and wait for SPIRE server and agents:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/spire/single_cluster?ref=c340ebd0c2ba2d43a9b162268a3606d017cd31e9
```

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=spire-server -n spire
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=spire-agent -n spire
```

Apply the ClusterSPIFFEID CR for the cluster:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/c340ebd0c2ba2d43a9b162268a3606d017cd31e9/examples/spire/single_cluster/clusterspiffeid-template.yaml
```

Ping from NSC to NSE:
```bash
kubectl exec pods/alpine -n ns-spire-upgrade -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec deployments/nse-kernel -n ns-spire-upgrade -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-spire-upgrade
```
