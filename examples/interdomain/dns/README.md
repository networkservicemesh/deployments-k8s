## Setup DNS for two clusters

This example shows how to simply configure three k8s clusters to know each other. 
Can be skipped if clusters setupped with external DNS.

## Run

Expose kube-dns service on cluster 1:

```bash
kubectl --kubeconfig=$KUBECONFIG1 expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer
```

Wait until IP of external DNS for cluster 1 is allocated:

```bash
kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store that IP:

```bash
ip1=$(kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
# If cluster uses DNS records for load-balancer, resolve them
if [[ $ip1 == *"no value"* ]]; then 
    ip1=$(kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip1=$(dig +short $ip1 | head -1)
fi
# if IPv6
if [[ $ip1 =~ ':' ]]; then ip1=[$ip1]; fi

echo Selected externalIP: $ip1 for cluster1
[[ ! -z $ip1 ]]
```

Expose kube-dns service on cluster 2:

```bash
kubectl --kubeconfig=$KUBECONFIG2 expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer
```

Wait until IP of external DNS for cluster 2 is allocated:

```bash
kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store that IP:

```bash
ip2=$(kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
# If cluster uses DNS records for load-balancer, resolve them
if [[ $ip2 == *"no value"* ]]; then 
    ip2=$(kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip2=$(dig +short $ip2 | head -1)
fi
# if IPv6
if [[ $ip2 =~ ':' ]]; then ip2=[$ip2]; fi

echo Selected externalIP: $ip2 for cluster2
[[ ! -z $ip2 ]]
```

Add DNS forwarding from cluster1 to cluster2:
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        k8s_external my.cluster1
        prometheus :9153
        forward . /etc/resolv.conf {
            max_concurrent 1000
        }
        loop
        reload 5s
    }
    my.cluster2:53 {
      forward . ${ip2}:53 {
        force_tcp
      }
    }
EOF
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  server.override: |
    k8s_external my.cluster2
  proxy1.server: |
    my.cluster2:53 {
      forward . ${ip2}:53 {
        force_tcp
      }
    }
EOF
```

Add DNS forwarding from cluster2 to cluster1:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        k8s_external my.cluster2
        prometheus :9153
        forward . /etc/resolv.conf {
            max_concurrent 1000
        }
        loop
        reload 5s
    }
    my.cluster1:53 {
      forward . ${ip1}:53 {
        force_tcp
      }
    }
EOF
```
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  server.override: |
    k8s_external my.cluster1
  proxy1.server: |
    my.cluster1:53 {
      forward . ${ip1}:53 {
        force_tcp
      }
    }
EOF
```

## Cleanup

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete service -n kube-system exposed-kube-dns
kubectl --kubeconfig=$KUBECONFIG2 delete service -n kube-system exposed-kube-dns
```

