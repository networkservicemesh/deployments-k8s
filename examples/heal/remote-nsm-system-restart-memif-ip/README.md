# Nsm system restart (remote case)

This example shows that NSM keeps working after restarting all management resources.

NSC and NSE are using the `memif` mechanism to connect to its local forwarder.
Forwarders are using the `wireguard` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic).

## Run

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal/remote-nsm-system-restart-memif-ip?ref=f6efb6868f9f9e34ba5d4105518b5d6ad174af5b
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-memif -n ns-remote-nsm-system-restart-memif-ip
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-memif -n ns-remote-nsm-system-restart-memif-ip
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec deployments/nsc-memif -n ns-remote-nsm-system-restart-memif-ip -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec deployments/nse-memif -n ns-remote-nsm-system-restart-memif-ip -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Restart nsm-system:
```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
```bash
kubectl create ns nsm-system
```
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/basic?ref=f6efb6868f9f9e34ba5d4105518b5d6ad174af5b
```

Ping from NSC to NSE:
```bash
result=$(kubectl exec deployments/nsc-memif -n ns-remote-nsm-system-restart-memif-ip -- vppctl ping 172.16.1.100 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

Ping from NSE to NSC:
```bash
result=$(kubectl exec deployments/nse-memif -n ns-remote-nsm-system-restart-memif-ip -- vppctl ping 172.16.1.101 repeat 4)
echo ${result}
! echo ${result} | grep -E -q "(100% packet loss)|(0 sent)|(no egress interface)"
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-remote-nsm-system-restart-memif-ip
```
