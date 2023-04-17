## Setup DNS for two clusters

This example shows how to simply configure three k8s clusters to know each other. 
Can be skipped if clusters setupped with external DNS.

## Run

1. Make sure that we have three KUBECONFIG files.

Check `KUBECONFIG1` env:

```bash
[[ ! -z $KUBECONFIG1 ]]
```

Check `KUBECONFIG2` env:

```bash
[[ ! -z $KUBECONFIG2 ]]
```

Check `KUBECONFIG3` env:

```bash
[[ ! -z $KUBECONFIG3 ]]
```

2. Get clusters IPs

Expose kube-dns service on the cluster1:
```bash
kubectl --kubeconfig=$KUBECONFIG1 expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer
```

Wait for setting externalIP:
```bash
kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store externalIP of the coredns
```bash
ip1=$(kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
if [[ $ip1 == *"no value"* ]]; then 
    ip1=$(kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip1=$(dig +short $ip1 | head -1)
fi
# if IPv6
if [[ $ip1 =~ ':' ]]; then ip1=[$ip1]; fi

echo Selected externalIP: $ip1 for cluster1
[[ ! -z $ip1 ]]
```

Expose kube-dns service on the cluster2:
```bash
kubectl --kubeconfig=$KUBECONFIG2 expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer
```

Wait for setting externalIP:
```bash
kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store externalIP of the coredns
```bash
ip2=$(kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
if [[ $ip2 == *"no value"* ]]; then 
    ip2=$(kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip2=$(dig +short $ip2 | head -1)
fi
# if IPv6
if [[ $ip2 =~ ":" ]]; then ip2=[$ip2]; fi

echo Selected externalIP: $ip2 for cluster2
[[ ! -z $ip2 ]]
```

Expose kube-dns service on the cluster3:
```bash
kubectl --kubeconfig=$KUBECONFIG3 expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer
```

Wait for setting externalIP:
```bash
kubectl --kubeconfig=$KUBECONFIG3 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store externalIP of the coredns
```bash
ip3=$(kubectl --kubeconfig=$KUBECONFIG3 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
if [[ $ip3 == *"no value"* ]]; then 
    ip3=$(kubectl --kubeconfig=$KUBECONFIG3 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip3=$(dig +short $ip3 | head -1)
fi
# if IPv6
if [[ $ip3 =~ ":" ]]; then ip3=[$ip3]; fi

echo Selected externalIP: $ip3 for cluster3
[[ ! -z $ip3 ]]
```

3. Update CoreDNS configmaps:

**For the first cluster:**

Apply CoreDNS config map:
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
    my.cluster3:53 {
      forward . ${ip3}:53 {
        force_tcp
      }
    }
EOF
```

Also if your cluster coredns is using `import` plugin it makes sense to use a custom-cordns configmap.
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  server.override: |
    k8s_external my.cluster1
  proxy2.server: |
    my.cluster2:53 {
      forward . ${ip2}:53 {
        force_tcp
      }
    }
  proxy3.server: |
    my.cluster3:53 {
      forward . ${ip3}:53 {
        force_tcp
      }
    }
EOF
```

**For the second cluster:**

Apply CoreDNS config map:
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
    my.cluster3:53 {
      forward . ${ip3}:53 {
        force_tcp
      }
    }
EOF
```

Also if your cluster coredns is using `import` plugin it makes sense to use a custom-cordns configmap.
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  server.override: |
    k8s_external my.cluster2
  proxy1.server: |
    my.cluster1:53 {
      forward . ${ip1}:53 {
        force_tcp
      }
    }
  proxy3.server: |
    my.cluster3:53 {
      forward . ${ip3}:53 {
        force_tcp
      }
    }
EOF
```

**For the third cluster:**

Apply CoreDNS config map:
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -f - <<EOF
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
        k8s_external my.cluster3
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
    my.cluster2:53 {
      forward . ${ip2}:53 {
        force_tcp
      }
    }
EOF
```

Also if your cluster coredns is using `import` plugin it makes sense to use a custom-coredns configmap.
```bash
kubectl --kubeconfig=$KUBECONFIG3 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  server.override: |
    k8s_external my.cluster3
  proxy1.server: |
    my.cluster1:53 {
      forward . ${ip1}:53 {
        force_tcp
      }
    }
  proxy2.server: |
    my.cluster2:53 {
      forward . ${ip2}:53 {
        force_tcp
      }
    }
EOF
```

## Cleanup

```bash
kubectl --kubeconfig=$KUBECONFIG1 delete service -n kube-system exposed-kube-dns
kubectl --kubeconfig=$KUBECONFIG2 delete service -n kube-system exposed-kube-dns
kubectl --kubeconfig=$KUBECONFIG3 delete service -n kube-system exposed-kube-dns
```
