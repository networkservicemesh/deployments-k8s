## Setup DNS for two clusters

This example shows how to simply configure two k8s clusters to know each other.


## Run

1. Make sure that you have two KUBECONFIG files.

Check `KUBECONFIG1` env:

```bash
[[ ! -z $KUBECONFIG1 ]]
```

Check `KUBECONFIG2` env:

```bash
[[ ! -z $KUBECONFIG2 ]]
```

2. Get clusters IPs

Switch to cluster1:

```bash
export KUBECONFIG=$KUBECONFIG1
```

Find first dns POD and get its nodeName:

```bash
node1=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o go-template='{{index (index (index  .items 0) "spec") "nodeName"}}')
```

Get IP of the node of cluster1:

```bash
ip1=$(kubectl get nodes $node1 -o go-template='{{range .status.addresses}}{{if eq .type "ExternalIP"}}{{.address}}{{end}}{{end}}')
echo Selected node IP: ${ip1:=$(kubectl get nodes $node1 -o go-template='{{range .status.addresses}}{{if eq .type "InternalIP"}}{{.address}}{{end}}{{end}}')}
```

Switch to cluster2:

```bash
export KUBECONFIG=$KUBECONFIG2
```

Find first dns POD and get its nodeName:

```bash
node2=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o go-template='{{index (index (index  .items 0) "spec") "nodeName"}}')
```

Get IP of the node of cluster2:

```bash
ip2=$(kubectl get nodes $node2 -o go-template='{{range .status.addresses}}{{if eq .type "ExternalIP"}}{{.address}}{{end}}{{end}}')
echo Selected node IP: ${ip2:=$(kubectl get nodes $node2 -o go-template='{{range .status.addresses}}{{if eq .type "InternalIP"}}{{.address}}{{end}}{{end}}')}
```

3. Update DNS service:

For the first cluster:
```bash
export KUBECONFIG=$KUBECONFIG1
```

```bash
kubectl apply -f service.yaml
```

For the second cluster:

```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
kubectl apply -f service.yaml
```

4. Update CoreDNS configmaps:

For the first cluster:

```bash
export KUBECONFIG=$KUBECONFIG1
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
    .:53 .:30053 {
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
      forward . ${ip2}:30053
    }
EOF
```

Apply CoreDNS config map for the cluster1:

```bash
kubectl apply -f configmap.yaml
```

For the second cluster:

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
    .:53 .:30053 {
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
      forward . ${ip1}:30053
    }
EOF
```

Apply CoreDNS config map for the cluster2:

```bash
kubectl apply -f configmap.yaml
```