# Test kernel to remote vlan connection

This example shows that NSCs can connect to each other by VLAN interface.
NSCs are using the `kernel` mechanism to connect to local forwarder.
Forwarders are using the `vlan` remote mechanism to set up the VLAN interface.

## Requires

Make sure that you have completed steps from [remotevlan](../../remotevlan) setup.

## Run

Deploy iperf server:

```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2RVlanInternal?ref=128125dbb39fc4bf1924a367c4fd23a8bb9afda3
```

Wait for applications ready:

```bash
kubectl -n ns-kernel2rvlan-internal wait --for=condition=ready --timeout=1m pod -l app=iperf1-s
```

Get the iperf-NSC pods:

```bash
NSCS=($(kubectl get pods -l app=iperf1-s -n ns-kernel2rvlan-internal --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'))
```

Start an iperf server in one NSC and client in another:

1. TCP with IPv4

    ```bash
    IP_ADDR=$(kubectl exec ${NSCS[0]} -c cmd-nsc -n ns-kernel2rvlan-internal -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    kubectl exec ${NSCS[0]} -c iperf-server -n ns-kernel2rvlan-internal -- iperf3 -sD -B ${IP_ADDR} -1
    kubectl exec ${NSCS[1]} -c iperf-server -n ns-kernel2rvlan-internal -- iperf3 -i0 -t 5 -c ${IP_ADDR}
    ```

2. UDP with IPv4:

    ```bash
    IP_ADDR=$(kubectl exec ${NSCS[1]} -c cmd-nsc -n ns-kernel2rvlan-internal -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    kubectl exec ${NSCS[1]} -c iperf-server -n ns-kernel2rvlan-internal -- iperf3 -sD -B ${IP_ADDR} -1
    kubectl exec ${NSCS[0]} -c iperf-server -n ns-kernel2rvlan-internal -- iperf3 -i0 -t 5 -u -c ${IP_ADDR}
    ```

3. TCP with IPv6:

    ```bash
    IP_ADDR=$(kubectl exec ${NSCS[0]} -c cmd-nsc -n ns-kernel2rvlan-internal -- ip -6 a s nsm-1 scope global | grep -oP '(?<=inet6\s)([0-9a-f:]+:+)+[0-9a-f]+')
    kubectl exec ${NSCS[0]} -c iperf-server -n ns-kernel2rvlan-internal -- iperf3 -sD -B ${IP_ADDR} -1
    kubectl exec ${NSCS[1]} -c iperf-server -n ns-kernel2rvlan-internal -- iperf3 -i0 -t 5 -6 -c ${IP_ADDR}
    ```

4. UDP with IPv6:

    ```bash
    IP_ADDR=$(kubectl exec ${NSCS[1]} -c cmd-nsc -n ns-kernel2rvlan-internal -- ip -6 a s nsm-1 scope global | grep -oP '(?<=inet6\s)([0-9a-f:]+:+)+[0-9a-f]+')
    kubectl exec ${NSCS[1]} -c iperf-server -n ns-kernel2rvlan-internal -- iperf3 -sD -B ${IP_ADDR} -1
    kubectl exec ${NSCS[0]} -c iperf-server -n ns-kernel2rvlan-internal -- iperf3 -i0 -t 5 -6 -u -c ${IP_ADDR}
    ```

## Cleanup

Delete the test namespace:

```bash
kubectl delete ns ns-kernel2rvlan-internal
```
