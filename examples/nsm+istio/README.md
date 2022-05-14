## CLUSTERS SETUP


### KIND
Setup

```bash
go install sigs.k8s.io/kind@v0.13.0 

kind create cluster --config kind-cluster-config.yaml --name cluster-1
kind create cluster --config kind-cluster-config.yaml --name cluster-2


kind get kubeconfig --name cluster-1 > /tmp/config1
kind get kubeconfig --name cluster-2 > /tmp/config2

export KUBECONFIG1=/tmp/config1
export KUBECONFIG2=/tmp/config2 
```


#### Kind Load balancer

Make sure that CIDR is fine for your kind clusters

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl --kubeconfig=$KUBECONFIG1 create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
cat > metallb-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.1.128/25
EOF
kubectl --kubeconfig=$KUBECONFIG1 apply -f metallb-config.yaml
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system


kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl --kubeconfig=$KUBECONFIG2 create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
cat > metallb-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.2.128/25
EOF
kubectl --kubeconfig=$KUBECONFIG2 apply -f metallb-config.yaml
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system

```

#### DNS

```bash
kubectl --kubeconfig=$KUBECONFIG1 expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer
kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
ip1=$(kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
if [[ $ip1 == *"no value"* ]]; then 
    ip1=$(kubectl --kubeconfig=$KUBECONFIG1 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip1=$(dig +short $ip1 | head -1)
fi
echo Selected externalIP: $ip1 for cluster1
kubectl --kubeconfig=$KUBECONFIG2 expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer
kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
ip2=$(kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
if [[ $ip2 == *"no value"* ]]; then 
    ip2=$(kubectl --kubeconfig=$KUBECONFIG2 get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip2=$(dig +short $ip2 | head -1)
fi
echo Selected externalIP: $ip2 for cluster2
[[ ! -z $ip2 ]]
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
      forward . ${ip2}:53 {
        force_tcp
      }
    }
EOF

kubectl --kubeconfig=$KUBECONFIG1 apply -f configmap.yaml

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
      forward . ${ip1}:53 {
        force_tcp
      }
    }
EOF

kubectl --kubeconfig=$KUBECONFIG2 apply -f configmap.yaml
```

### SPIRE

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./spire/cluster1
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./spire/cluster2

bundle1=$(kubectl --kubeconfig=$KUBECONFIG1 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
bundle2=$(kubectl --kubeconfig=$KUBECONFIG2 exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)

echo $bundle2 | kubectl --kubeconfig=$KUBECONFIG1 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster2"

echo $bundle1 | kubectl --kubeconfig=$KUBECONFIG2 exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster1"
```



## NSM SETUP

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./nsm/cluster1
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./nsm/cluster2
```


### Istio

#### Install

```bash
export KUBECONFIG=$KUBECONFIG2
```

```bash
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin
istioctl install --set profile=minimal -y
istioctl proxy-status
```

### Verify NSM+ISTIO

Install networkservice:
```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -f networkservice.yaml
```

Start alpine networkservicemesh client:

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f productpage/productpage.yaml
```

Start alpine networkservicemesh endpoint (auto-scale):

```bash
kubectl --kubeconfig=$KUBECONFIG2 apply -k nse-auto-scale 
```

Install istio booking example
```bash
kubectl --kubeconfig=$KUBECONFIG2 label namespace default istio-injection=enabled

kubectl --kubeconfig=$KUBECONFIG2 apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/bookinfo/platform/kube/bookinfo.yaml
```

Verify connectivity:
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/productpage-v1 -c cmd-nsc -- apk add curl
kubectl --kubeconfig=$KUBECONFIG1 exec deploy/productpage-v1 -c cmd-nsc -- curl -s productpage.default:9080/productpage | grep -o "<title>.*</title>"
```

Port forward and check browser by `127.0.0.1:9080`
```bash
kubectl --kubeconfig=$KUBECONFIG1 port-forward deploy/productpage-v1  9080:9080
```


Delete ratings on cluster2
```bash
kubectl --kubeconfig=$KUBECONFIG2 delete deploy ratings-v1
```

Start ratings on cluster1
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f ratings/ratings.yaml
```



Port forward and check browser by `127.0.0.1:9080`
```bash
kubectl port-forward deploy/productpage-v1  9080:9080
```


## Cleanup


```bash
WH=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG1 delete mutatingwebhookconfiguration ${WH}

WH=$(kubectl --kubeconfig=$KUBECONFIG2 get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG2 delete mutatingwebhookconfiguration ${WH}

kubectl --kubeconfig=$KUBECONFIG1 delete -k ./nsm/cluster1
kubectl --kubeconfig=$KUBECONFIG2 delete -k ./nsm/cluster2

kubectl --kubeconfig=$KUBECONFIG2 delete crd spiffeids.spiffeid.spiffe.io
kubectl --kubeconfig=$KUBECONFIG2 delete ns spire

kubectl --kubeconfig=$KUBECONFIG1 delete crd spiffeids.spiffeid.spiffe.io
kubectl --kubeconfig=$KUBECONFIG1 delete ns spire
```