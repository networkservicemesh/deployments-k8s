# NSM component restarts

This example shows that NSM keeps working after NSM components restarts several times.
We deploy two clients - one of them supports only Control Plane-based healing (client-cp), the other supports full healing (client).
Please note that for convenience, this example doesn't use NSM annotations, but instead deploys bare NSC applications.

NSCs and NSE are using the `kernel` mechanism to connect to its local forwarder.
Forwarders are using the `vxlan` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) setup.

## Run

Deploy NSCs and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/heal_extended/component-restart?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=client -n ns-component-restart
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
# Iterates over NSCs and checks connectivity to NSE (sends pings)
function connectivity_check() {
echo -e "\n-- Connectivity check --"
nscs=$(kubectl  get pods -l app=client -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}" -n ns-component-restart)
for nsc in $nscs
do
    echo -e "\nNSC: $nsc"
    echo "Wait for NSM interface to be ready"
    for i in $(seq 1 $INTERFACE_READY_WAIT)
    do
        if [ $i -eq $INTERFACE_READY_WAIT ] ; then
          echo "NSM interface is not ready after $INTERFACE_READY_WAIT s"
          return 1
        fi
        sleep 1
        routes=$(kubectl exec -n ns-component-restart $nsc -- ip route)
        nseAddr=$(echo $routes | grep -Eo '172\.16\.1\.[0-9]{1,3}')
        test $? -ne 0 || break
    done
    echo "NSM interface is ready"
    kubectl exec $nsc -n ns-component-restart -- ping -c2 -i 0.5 $nseAddr || return 2
done
return 0
}

# Restarts NSM components and checks connectivity.
# $1 is used to define NSM-component type (e.g. forwarder or nsmgr)
# -a defines the restart method.
#   if specified - all NSM-pods of this type will be restarted at the same time.
#   else - they will be restarted one by one.
function restart_nsm_component() {
nsm_component=$1
shift

a_flag=0
while getopts 'a' flag; do
  case "${flag}" in
    a) a_flag=1 ;;
  esac
done

for i in $(seq 1 $N_RESTARTS)
do
    echo -e "\n-------- $nsm_component restart $i of $N_RESTARTS --------"
    echo "Wait $DELAY sec before restart..."
    sleep $DELAY
    if [ $a_flag -eq 1 ]; then
        kubectl delete pod -n nsm-system -l app=${nsm_component}
        kubectl wait --for=condition=ready --timeout=1m pod -l app=${nsm_component} -n nsm-system || return 1
        connectivity_check || return 2
    else
        nodes=$(kubectl get pods -l app=${nsm_component} -n nsm-system --template '{{range .items}}{{.spec.nodeName}}{{"\n"}}{{end}}')
        for node in $nodes
        do
            kubectl delete pod -n nsm-system -l app=${nsm_component} --field-selector spec.nodeName==${node}
            kubectl wait --for=condition=ready --timeout=1m pod -l app=${nsm_component} --field-selector spec.nodeName==${node} -n nsm-system || return 1
            connectivity_check || return 2
        done
    fi
done
return 0
}
```

Check the connection before restarts:
```bash
connectivity_check
```

Restart forwarders one by one:
```bash
restart_nsm_component forwarder-vpp
```

Restart all forwarders at the same time:
```bash
restart_nsm_component forwarder-vpp -a
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-component-restart
```
