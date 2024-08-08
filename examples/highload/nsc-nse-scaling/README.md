# Continuous NSC and NSE scaling

This scenario checks memory, goroutine and `vpp` interface leaks. We continuously scale up and down NSCs and NSEs.
Between scaling up and down we also check that all NSCs connections are alive. 

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Deploy metrics server:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/56d14f1cd3c8e1b3070e78b8686138ee98e9681d/examples/highload/nsc-nse-scaling/metrics-server.yaml
```

Wait for metrics server's readiness:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l k8s-app=metrics-server -n kube-system
```

Collect pod metrics before scaling:
```bash
mkdir -p $ARTIFACTS_DIR/highload/nsc-nse-scaling
kubectl top pod -A > $ARTIFACTS_DIR/highload/nsc-nse-scaling/metrics-before
```

Deploy NSCs and NSEs, 0 replicas each:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/highload/nsc-nse-scaling?ref=56d14f1cd3c8e1b3070e78b8686138ee98e9681d
```

A function to check connectivity between NSCs and NSEs:
```bash
function ping() {
    nscs=$(kubectl get pods -l app=nsc-kernel -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-nsc-nse-scaling)
    for nsc in $nscs; do
        ipv4=$(kubectl exec $nsc -n ns-nsc-nse-scaling -- ip route show dev nsm-1 | cut -d' ' -f1 | tr '\n' ' ' | cut -d' ' -f1)
        kubectl exec $nsc -n ns-nsc-nse-scaling -- ping -c2 -i0.5 $ipv4
        if [[ "$?" != 0 ]]; then
            echo "failed to ping from $nsc"
            return 1
        fi
    done
    return 0
}
```

Define the number of scaling iterations:
```bash
SCALING_COUNT=50
```

Main loop function:
```bash
function scaling() {
    for i in {1..$SCALING_COUNT}; do
        echo "Attempt #$i"

        kubectl scale deployment -n ns-nsc-nse-scaling nsc-kernel --replicas=10
        kubectl scale deployment -n ns-nsc-nse-scaling nse-kernel --replicas=10
        sleep 60

        ping
        if [[ "$?" != 0 ]]; then
            echo "failed to ping!!!!!!!!!"
        fi 

        kubectl scale deployment -n ns-nsc-nse-scaling nsc-kernel --replicas=0
        kubectl scale deployment -n ns-nsc-nse-scaling nse-kernel --replicas=0
        sleep 60
    done
    return 0
}
```


Run the loop:
```bash
scaling
```

Collect metrics after the test:
```bash
kubectl top pod -A > $ARTIFACTS_DIR/highload/nsc-nse-scaling/metrics-after
```

Collect `vpp` interfaces from the forwarders:
```bash
fwds=$(kubectl get pods -l app=forwarder-vpp -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
for fwd in $fwds; do
    kubectl exec -n nsm-system $fwd -- vppctl show int > $ARTIFACTS_DIR/highload/nsc-nse-scaling/$fwd-ifaces
done
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-nsc-nse-scaling
kubectl delete -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/56d14f1cd3c8e1b3070e78b8686138ee98e9681d/examples/highload/nsc-nse-scaling/metrics-server.yaml
```
