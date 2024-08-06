# Continuous NSC and NSE scaling

This scenario checks memory, goroutine and `vpp` interface leaks. We continuously scale up and down NSCs and NSEs.
Between scaling up and down we also check that all NSCs connections are alive. 

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Deploy NSCs and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal_extended/component-restart?ref=56d14f1cd3c8e1b3070e78b8686138ee98e9681d
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l k8s-app=metrics-server -n ns-nsc-nse-scaling
```

Define env variables for scripts:
```bash
# N_RESTARTS - number of restarts
# TEST_TIME - determines how long the test will take (sec)
# DELAY - delay between restarts (sec)
# INTERFACE_READY_WAIT - how long do we wait for the interface to be ready (sec). Equals to NSM_REQUEST_TIMEOUT * 2 (for Close and Request)
N_RESTARTS=15
TEST_TIME=900
DELAY=$(($TEST_TIME/$N_RESTARTS))
INTERFACE_READY_WAIT=10
```

Test functions:
```bash
ping() {
  nscs=$(kubectl get pods -l app=nsc-kernel -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-nsc-nse-scaling)
  for nsc in $nscs; do
      ipv4=$(kubectl exec $nsc -n ns-nsc-nse-scaling -- ip route show dev nsm-1 | cut -d' ' -f1 | tr '\n' ' ' | cut -d' ' -f1)
      kubectl exec $nsc -n ns-nsc-nse-scaling -- ping -c2 -i0.5 $ipv4 2>&1 > error
      if [[ "$?" != 0 ]]; then
          echo "failed to ping from $nsc"
          echo "address: $ipv4"
          echo "date: $(date)"
          echo "Error:"
          cat error
          return 1
      fi
  done
  return 1
}
```

Main loop:
```bash
for i in {1..20}; do
    echo "Attempt #$i"

    kubectl scale deployment -n ns-nsc-nse-scaling nsc-kernel --replicas=10
    kubectl scale deployment -n ns-nsc-nse-scaling nse-kernel --replicas=10s
    sleep 60

    ping
    if [[ "$?" != 0 ]]; then
        echo "failed to ping!!!!!!!!!"
    fi 

    kubectl scale deployment -n ns-nsc-nse-scaling nsc-kernel --replicas=0;
    kubectl scale deployment -n ns-nsc-nse-scaling nse-kernel --replicas=0;
    sleep 60
done
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-nsc-nse-scaling
```
