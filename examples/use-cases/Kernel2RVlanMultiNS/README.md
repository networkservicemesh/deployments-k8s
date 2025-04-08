# Test kernel to remote vlan connection

This example shows that NSCs can connect to a cluster external entity by a VLAN interface. The clients in this topology are running in different k8s namespaces and connecting to dfferent services provided by three endpoint.
NSCs are using the `kernel` mechanism to connect to local forwarder.
Forwarders are using the `vlan` remote mechanism to set up the VLAN interface.

## Requires

Make sure that you have completed steps from [remotevlan_ovs](../../remotevlan_ovs) or [remotevlan_vpp](../../remotevlan_vpp) setup.

## Run

Deployment in first namespace:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2RVlanMultiNS/ns-1?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Deployment in second namespace:
```bash
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/0e8c3ce7819f0640d955dc1136a64ecff2ae8c56/examples/use-cases/Kernel2RVlanMultiNS/ns-2/ns-kernel2vlan-multins-2.yaml
kubectl apply -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/0e8c3ce7819f0640d955dc1136a64ecff2ae8c56/examples/use-cases/Kernel2RVlanMultiNS/ns-2/netsvc.yaml
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2RVlanMultiNS/ns-2?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Deployment in third namespace:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/Kernel2RVlanMultiNS/ns-3?ref=0e8c3ce7819f0640d955dc1136a64ecff2ae8c56
```

Wait for applications ready:

```bash
kubectl -n ns-kernel2vlan-multins-1 wait --for=condition=ready --timeout=1m pod -l app=nse-remote-vlan
```

```bash
kubectl -n ns-kernel2vlan-multins-1 wait --for=condition=ready --timeout=1m pod -l app=alpine-1
```

```bash
kubectl -n ns-kernel2vlan-multins-2 wait --for=condition=ready --timeout=1m pod -l app=nse-remote-vlan
```

```bash
kubectl -n ns-kernel2vlan-multins-2 wait --for=condition=ready --timeout=1m pod -l app=alpine-2
```

```bash
kubectl -n ns-kernel2vlan-multins-2 wait --for=condition=ready --timeout=1m pod -l app=alpine-3
```

```bash
kubectl -n ns-kernel2vlan-multins-3 wait --for=condition=ready --timeout=1m pod -l app=alpine-4
```

Setup a docker container for traffic test:

```bash
docker run --cap-add=NET_ADMIN --rm -d --network bridge-2 --name rvm-tester aeciopires/nettools:1.0.0 tail -f /dev/null
docker exec rvm-tester ip link set eth0 down
docker exec rvm-tester ip link add link eth0 name eth0.100 type vlan id 100
docker exec rvm-tester ip link add link eth0 name eth0.300 type vlan id 300
docker exec rvm-tester ip link set eth0 up
docker exec rvm-tester ip route add default dev eth0
docker exec rvm-tester ip addr add 172.10.0.254/24 dev eth0.100
docker exec rvm-tester ip addr add 172.10.1.254/24 dev eth0
docker exec rvm-tester ip addr add 172.10.2.254/24 dev eth0.300
docker exec rvm-tester ethtool -K eth0 tx off
```

Get the NSC pods from first k8s namespace:

```bash
NSCS=($(kubectl get pods -l app=alpine-1 -n ns-kernel2vlan-multins-1 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'))
```

Check the MTU adjustment for the NSC pods from first k8s namespace::

```bash
status=0
LINK_MTU=$(docker exec kind-worker cat /sys/class/net/ext_net1/mtu)
for nsc in "${NSCS[@]}"
do
  MTU=$(kubectl exec ${nsc} -c cmd-nsc -n ns-kernel2vlan-multins-1 -- cat /sys/class/net/nsm-1/mtu)

  echo "$LINK_MTU vs $MTU"

  if test "${MTU}" = ""
    then
      status=1
  fi
  if test $MTU -ne $LINK_MTU
    then
      status=2
  fi
done
if test ${status} -ne 0
  then
    false
fi
```

Get the IP addresses for NSCs from first k8s namespace:

```bash
declare -A IP_ADDR
for nsc in "${NSCS[@]}"
do
  IP_ADDR[$nsc]=$(kubectl exec ${nsc} -n ns-kernel2vlan-multins-1 -c alpine -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
done
```

Check first vlan from tester container:

```bash
status=0
for nsc in "${NSCS[@]}"
do
  for vlan_if_name in eth0.100 eth0.300
  do
    docker exec rvm-tester ping -w 1 -I ${vlan_if_name} -c 1 ${IP_ADDR[$nsc]}
    if test $? -eq 0
      then
        status=2
    fi
  done
  docker exec rvm-tester ping -I eth0 -c 1 ${IP_ADDR[$nsc]}
  if test $? -ne 0
    then
      status=1
  fi
done
if test ${status} -eq 1
  then
    false
fi
```

Get the NSC pods from second k8s namespace:

```bash
NSCS_BLUE=($(kubectl get pods -l app=alpine-2 -n ns-kernel2vlan-multins-2 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'))
NSCS_GREEN=($(kubectl get pods -l app=alpine-3 -n ns-kernel2vlan-multins-2 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'))
```

Check the MTU adjustment for the NSC pods from second k8s namespace:

```bash
status=0
for nsc in "${NSCS_BLUE[@]} ${NSCS_GREEN[@]}"
do
  MTU=$(kubectl exec ${nsc} -c cmd-nsc -n ns-kernel2vlan-multins-2 -- cat /sys/class/net/nsm-1/mtu)

  echo "$LINK_MTU vs $MTU"

  if test "${MTU}" = ""
    then
      status=1
  fi
  if test $MTU -ne $LINK_MTU
    then
      status=2
  fi
done
if test ${status} -ne 0
  then
    false
fi
```

Get the IP addresses for NSCs from second k8s namespace:

```bash
declare -A IP_ADDR_BLUE
for nsc in "${NSCS_BLUE[@]}"
do
  IP_ADDR_BLUE[$nsc]=$(kubectl exec ${nsc} -n ns-kernel2vlan-multins-2 -c alpine -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
done
declare -A IP_ADDR_GREEN
for nsc in "${NSCS_GREEN[@]}"
do
  IP_ADDR_GREEN[$nsc]=$(kubectl exec ${nsc} -n ns-kernel2vlan-multins-2 -c alpine -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
done
```

Check vlan (300) from tester container:

```bash
status=0
for nsc in "${NSCS_BLUE[@]}"
do
  for vlan_if_name in eth0.100 eth0
  do
    docker exec rvm-tester ping -w 1 -I ${vlan_if_name} -c 1 ${IP_ADDR_BLUE[$nsc]}
    if test $? -eq 0
      then
        status=2
    fi
  done
  docker exec rvm-tester ping -I eth0.300 -c 1 ${IP_ADDR_BLUE[$nsc]}
  if test $? -ne 0
    then
      status=1
  fi
done
for nsc in "${NSCS_GREEN[@]}"
do
  for vlan_if_name in eth0.100 eth0
  do
    docker exec rvm-tester ping -w 1 -I ${vlan_if_name} -c 1 ${IP_ADDR_GREEN[$nsc]}
    if test $? -eq 0
      then
        status=2
    fi
  done
  docker exec rvm-tester ping -I eth0.300 -c 1 ${IP_ADDR_GREEN[$nsc]}
  if test $? -ne 0
    then
      status=1
  fi
done
if test ${status} -eq 1
  then
    false
fi
```

Delete the NSCs connected to blue-bridge network service:

```bash
kubectl delete deployment alpine-2-bg -n ns-kernel2vlan-multins-2
```

Check vlan (300) from tester container:

```bash
status=0
for nsc in "${NSCS_GREEN[@]}"
do
  docker exec rvm-tester ping -I eth0.300 -c 1 ${IP_ADDR_GREEN[$nsc]}
  if test $? -ne 0
    then
      status=1
  fi
done
if test ${status} -eq 1
  then
    false
fi
```

Get the NSC pods from the third k8s namespace:

```bash
NSCS=($(kubectl get pods -l app=alpine-4 -n ns-kernel2vlan-multins-3 --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'))
```

Check the MTU adjustment for the NSC pods from the third k8s namespace:

```bash
status=0
for nsc in "${NSCS[@]}"
do
  MTU=$(kubectl exec ${nsc} -c cmd-nsc -n ns-kernel2vlan-multins-3 -- cat /sys/class/net/nsm-1/mtu)

  echo "$LINK_MTU vs $MTU"

  if test "${MTU}" = ""
    then
      status=1
  fi
  if test $MTU -ne $LINK_MTU
    then
      status=2
  fi
done
if test ${status} -ne 0
  then
    false
fi
```

Get the IP addresses for NSCs from the third k8s namespace:

```bash
declare -A IP_ADDR
for nsc in "${NSCS[@]}"
do
  IP_ADDR[$nsc]=$(kubectl exec ${nsc} -n ns-kernel2vlan-multins-3 -c alpine -- ip -4 addr show nsm-1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
done
```

Check first vlan from tester container:

```bash
status=0
for nsc in "${NSCS[@]}"
do
  for vlan_if_name in eth0 eth0.300
  do
    docker exec rvm-tester ping -I ${vlan_if_name} -w 1 -c 1 ${IP_ADDR[$nsc]}
    if test $? -eq 0
      then
        status=2
    fi
  done
  docker exec rvm-tester ping -I eth0.100 -c 1 ${IP_ADDR[$nsc]}
  if test $? -ne 0
    then
      status=1
  fi
done
if test ${status} -eq 1
  then
    false
fi
```

## Cleanup

Delete the tester container and image:

```bash
docker stop rvm-tester
true
```

Delete the test namespace:

```bash
kubectl delete ns ns-kernel2vlan-multins-1
```

```bash
kubectl delete ns ns-kernel2vlan-multins-2
```

```bash
kubectl delete ns ns-kernel2vlan-multins-3
```
