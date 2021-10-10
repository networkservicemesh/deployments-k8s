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

Switch to cluster1:

```bash
export KUBECONFIG=$KUBECONFIG1
```

Expose kube-dns service:
```bash
kubectl expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=UDP --name=exposed-kube-dns --type=LoadBalancer
```

Wait for setting externalIP:
```bash
kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store externalIP of the coredns
```bash
ip1=$(kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
echo "Cluster1: External IP of exposed-kube-dns is $ip1"
```

Switch to cluster2:

```bash
export KUBECONFIG=$KUBECONFIG2
```

Expose kube-dns service:
```bash
kubectl expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=UDP --name=exposed-kube-dns --type=LoadBalancer
```

Wait for setting externalIP:
```bash
kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store externalIP of the coredns
```bash
ip2=$(kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
echo "Cluster2: External IP of exposed-kube-dns is $ip2"
```

Switch to cluster3:

```bash
export KUBECONFIG=$KUBECONFIG3
```

Expose kube-dns service:
```bash
kubectl expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=UDP --name=exposed-kube-dns --type=LoadBalancer
```

Wait for setting externalIP:
```bash
kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store externalIP of the coredns
```bash
ip3=$(kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
echo "Cluster3: External IP of exposed-kube-dns is $ip3"
```


3. Update CoreDNS configmaps:

**For the first cluster:**

```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
---
cat > configmap.yaml <<EOF
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
      forward . ${ip2}:53
    }
    my.cluster3:53 {
      forward . ${ip3}:53
    }
EOF
```

Apply CoreDNS config map:

```bash
kubectl apply -f configmap.yaml
```

Also if your cluster coredns is using `import` plugin it makes sense to use a custom-cordns configmap.

```bash
cat > custom-configmap.yaml <<EOF
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
      forward . ${ip2}:53
    }
  proxy3.server: |
    my.cluster3:53 {
      forward . ${ip3}:53
    }
EOF
```

Apply custom CoreDNS config map:
```bash
kubectl apply -f custom-configmap.yaml 
```


**For the second cluster:**

```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
cat > configmap.yaml <<EOF
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
      forward . ${ip1}:53
    }
    my.cluster3:53 {
      forward . ${ip3}:53
    }
EOF
```

Also if your cluster coredns is using `import` plugin it makes sense to use a custom-cordns configmap.

```bash
cat > custom-configmap.yaml <<EOF
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
      forward . ${ip1}:53
    }
  proxy3.server: |
    my.cluster3:53 {
      forward . ${ip3}:53
    }
EOF
```

Apply custom CoreDNS config map:
```bash
kubectl apply -f custom-configmap.yaml 
```

Apply CoreDNS config map:

```bash
kubectl apply -f configmap.yaml
```


**For the third cluster:**

```bash
export KUBECONFIG=$KUBECONFIG3
```

```bash
cat > configmap.yaml <<EOF
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
      forward . ${ip1}:53
    }
    my.cluster2:53 {
      forward . ${ip2}:53
    }
EOF
```

Apply CoreDNS config map:

```bash
kubectl apply -f configmap.yaml
```
Also if your cluster coredns is using `import` plugin it makes sense to use a custom-coredns configmap.

```bash
cat > custom-configmap.yaml <<EOF
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
      forward . ${ip1}:53
    }
  proxy2.server: |
    my.cluster2:53 {
      forward . ${ip2}:53
    }
EOF
```

Apply custom CoreDNS config map:
```bash
kubectl apply -f custom-configmap.yaml 
```


## Cleanup

```bash
export KUBECONFIG=$KUBECONFIG1 && kubectl delete service -n kube-system exposed-kube-dns
export KUBECONFIG=$KUBECONFIG2 && kubectl delete service -n kube-system exposed-kube-dns
export KUBECONFIG=$KUBECONFIG3 && kubectl delete service -n kube-system exposed-kube-dns
```

