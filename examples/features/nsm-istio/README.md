# NSM + Istio

## Run

### Setup enviroment and clusters

**1. Set enviroment**
```bash
export CTX_CLUSTER1=cluster1
export CTX_CLUSTER2=cluster2

export CMD_ISTIO_PROXY_PATH="/home/rejmond/Projects/NSM/cmd-nse-istio-proxy"

# Add istioctl to $PATH
export ISTIO_PATH="/home/rejmond/istio-1.13.3"
export PATH=$ISTIO_PATH/bin:$PATH
```

**Create network interface**

```bash
sudo ip link add name mylo type dummy
sudo ifconfig mylo up
sudo ip a add 172.16.8.0/24 dev mylo

```

**Create clusters**

```bash
cat > cluster-1.yaml <<EOF
---
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: 172.16.8.0
  apiServerPort: 6443
nodes:
- role: control-plane
- role: worker
EOF

cat > cluster-2.yaml <<EOF
---
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: 172.16.8.0
  apiServerPort: 6444
nodes:
- role: control-plane
- role: worker
EOF

kind create cluster --config cluster-1.yaml --name "${CTX_CLUSTER1}"
kind create cluster --config cluster-2.yaml --name "${CTX_CLUSTER2}"

kubectl config rename-context kind-"${CTX_CLUSTER1}" "${CTX_CLUSTER1}"
kubectl config rename-context kind-"${CTX_CLUSTER2}" "${CTX_CLUSTER2}"
```

**Enable LoadBalancer**

```bash
kubectl --context="${CTX_CLUSTER1}" apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl --context="${CTX_CLUSTER1}" apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
kubectl --context="${CTX_CLUSTER1}" apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-configmap.yaml

cat > metallb-config-1.yaml <<EOF
---
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

kubectl --context="${CTX_CLUSTER1}" apply -f metallb-config-1.yaml


kubectl --context="${CTX_CLUSTER2}" apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl --context="${CTX_CLUSTER2}" apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
kubectl --context="${CTX_CLUSTER2}" apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-configmap.yaml

cat > metallb-config-2.yaml <<EOF
---
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

kubectl --context="${CTX_CLUSTER2}" apply -f metallb-config-2.yaml


kubectl --context="${CTX_CLUSTER1}" wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system 
kubectl --context="${CTX_CLUSTER2}" wait --for=condition=ready --timeout=5m pod -l app=metallb -n metallb-system 

```

**Connect DNS**

```bash
# Expose DNS for the cluster1
kubectl expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer --context="${CTX_CLUSTER1}"
kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}' --context="${CTX_CLUSTER1}"

ip_cluster1=$(kubectl  --context="${CTX_CLUSTER1}"  get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
if [[ $ip_cluster1 == *"no value"* ]]; then 
    ip_cluster1=$(kubectl --context="${CTX_CLUSTER1}" get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip_cluster1=$(dig +short $ip_cluster1 | head -1)
fi
echo Selected externalIP: $ip_cluster1 for cluster 1

```

```bash
# Expose DNS for the cluster2

kubectl expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer --context="${CTX_CLUSTER2}"
kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}' --context="${CTX_CLUSTER2}"

ip_cluster2=$(kubectl --context="${CTX_CLUSTER2}" get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
if [[ $ip_cluster2 == *"no value"* ]]; then 
    ip_cluster2=$(kubectl --context="${CTX_CLUSTER2}" get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    ip_cluster2=$(dig +short $ip_cluster2 | head -1)
fi
echo Selected externalIP: $ip_cluster2 for cluster 2

```

```bash
cat > configmap-dns-1.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        log
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
      forward . ${ip_cluster2}:53 {
        force_tcp
      }
    }
EOF

kubectl apply -f configmap-dns-1.yaml --context="${CTX_CLUSTER1}"

```

```bash
cat > configmap-dns-2.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        log
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
      forward . ${ip_cluster1}:53 {
        force_tcp
      }
    }
EOF

kubectl apply -f configmap-dns-2.yaml --context="${CTX_CLUSTER2}"

```

**Install Spire**

```bash
kubectl --context="${CTX_CLUSTER1}" apply -k ./spire/cluster1
kubectl --context="${CTX_CLUSTER2}" apply -k ./spire/cluster2

kubectl --context="${CTX_CLUSTER1}" wait -n spire --timeout=5m --for=condition=ready pod -l app=spire-agent
kubectl --context="${CTX_CLUSTER1}" wait -n spire --timeout=5m --for=condition=ready pod -l app=spire-server
kubectl --context="${CTX_CLUSTER2}" wait -n spire --timeout=5m --for=condition=ready pod -l app=spire-agent
kubectl --context="${CTX_CLUSTER2}" wait -n spire --timeout=5m --for=condition=ready pod -l app=spire-server

bundle1=$(kubectl --context="${CTX_CLUSTER1}" exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)
bundle2=$(kubectl --context="${CTX_CLUSTER2}" exec spire-server-0 -n spire -- bin/spire-server bundle show -format spiffe)

echo $bundle2 | kubectl --context="${CTX_CLUSTER1}" exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster2"
echo $bundle1 | kubectl --context="${CTX_CLUSTER2}" exec -i spire-server-0 -n spire -- bin/spire-server bundle set -format spiffe -id "spiffe://nsm.cluster1"

```

**Build and upload nse-istio-cmd**

```bash
docker build -t cmd-nse-istio-proxy:dev ${CMD_ISTIO_PROXY_PATH}

kind load docker-image cmd-nse-istio-proxy:dev --name "${CTX_CLUSTER1}"
kind load docker-image cmd-nse-istio-proxy:dev --name "${CTX_CLUSTER2}"

```

**Install NSM**

```bash
kubectl create ns nsm-system --context="${CTX_CLUSTER1}"
kubectl create ns nsm-system --context="${CTX_CLUSTER2}"

kubectl apply -k ./clusters-configuration/cluster1 --context="${CTX_CLUSTER1}"
kubectl apply -k ./clusters-configuration/cluster2 --context="${CTX_CLUSTER2}"

kubectl --context="${CTX_CLUSTER1}" get services nsmgr-proxy -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
kubectl --context="${CTX_CLUSTER2}" get services nsmgr-proxy -n nsm-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'

kubectl --context="${CTX_CLUSTER1}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=forwarder-vpp
kubectl --context="${CTX_CLUSTER1}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=nsmgr
kubectl --context="${CTX_CLUSTER1}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=nsmgr-proxy
kubectl --context="${CTX_CLUSTER1}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=registry
kubectl --context="${CTX_CLUSTER1}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=registry-proxy
kubectl --context="${CTX_CLUSTER1}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=admission-webhook-k8s

kubectl --context="${CTX_CLUSTER2}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=forwarder-vpp
kubectl --context="${CTX_CLUSTER2}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=nsmgr
kubectl --context="${CTX_CLUSTER2}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=nsmgr-proxy
kubectl --context="${CTX_CLUSTER2}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=registry
kubectl --context="${CTX_CLUSTER2}" wait -n nsm-system --timeout=5m --for=condition=ready pod -l app=registry-proxy

```

**Install Istio**

```bash
istioctl install --context="${CTX_CLUSTER2}" --set profile=demo -y

```

### Run experiment

**Create NSE supplier on cluster #2**


```bash
NAMESPACE1=($(kubectl --context="${CTX_CLUSTER2}" create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7d08174431e049a31fdaf574e03f12ea965c4f5b/examples/interdomain/usecases/namespace.yaml)[0])
NAMESPACE1=${NAMESPACE1:10}

```

```bash
kubectl --context="${CTX_CLUSTER2}" label namespace ${NAMESPACE1} istio-injection=enabled

```

```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: $NAMESPACE1

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-supplier-k8s?ref=bcb5016abfef9cdfe76e31c03491cadfb8bd08d3

patchesStrategicMerge:
- patch-supplier.yaml

configMapGenerator:
  - name: supplier-pod-template-configmap
    files:
      - ./pod-template.yaml
EOF

```

```bash
cat > patch-supplier.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-supplier-k8s
spec:
  template:
    spec:
      containers:
        - name: nse-supplier
          env:
            - name: NSM_PAYLOAD
              value: IP
            - name: NSM_SERVICE_NAME
              value: autoscale-istio-proxy-responder
            - name: NSM_LABELS
              value: app:istio-proxy-responder-supplier
            - name: NSM_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: NSM_POD_DESCRIPTION_FILE
              value: /run/supplier/pod-template.yaml
          volumeMounts:
            - name: pod-file
              mountPath: /run/supplier
              readOnly: true
      volumes:
        - name: pod-file
          configMap:
            name: supplier-pod-template-configmap
EOF

kubectl --context="${CTX_CLUSTER2}" apply -k .

```

**Register Network Service**


```bash
kubectl --context="${CTX_CLUSTER2}" apply -f ./autoscale-netsvc.yaml

```

**Create NSC on cluster #1**

```bash
NAMESPACE2=($(kubectl --context="${CTX_CLUSTER1}" create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/7d08174431e049a31fdaf574e03f12ea965c4f5b/examples/interdomain/usecases/namespace.yaml)[0])
NAMESPACE2=${NAMESPACE2:10}

```

```bash
cat > workload1-deployment.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: workload1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: workload1
  template:
    metadata:
      labels:
        app: workload1
      annotations:
        networkservicemesh.io: "kernel://autoscale-istio-proxy-responder@my.cluster2/nsm-1"
    spec:
      containers:
        - name: hello-world
          image: strm/helloworld-http
          imagePullPolicy: IfNotPresent
          stdin: true
          tty: true
EOF

kubectl --context="${CTX_CLUSTER1}" apply -n ${NAMESPACE2} -f workload1-deployment.yaml 

kubectl --context="${CTX_CLUSTER1}" wait --for=condition=ready --timeout=5m pod -l app=workload1 -n ${NAMESPACE2}
 
NSC=$(kubectl --context="${CTX_CLUSTER1}" get pods -l app=workload1 -n ${NAMESPACE2} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo $NSC

```

**Create Workload2 on cluster #2**

```bash
cat > workload2-deploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: workload2
  labels:
    app: workload2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: workload2
  template:
    metadata:
      labels:
        app: workload2
    spec:
      containers:
      - name: hello-world
        image: strm/helloworld-http
        imagePullPolicy: IfNotPresent
        stdin: true
        tty: true
EOF

kubectl apply --context="${CTX_CLUSTER2}" -n ${NAMESPACE1} -f workload2-deploy.yaml

cat > workload2-svc.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: workload2
spec:
  ports:
  - name: http
    port: 80
    targetPort: 80
  selector:
    app: workload2
  type: ClusterIP
EOF

kubectl apply --context="${CTX_CLUSTER2}" -n ${NAMESPACE1} -f workload2-svc.yaml

```

**Wait for NSE**

```bash
kubectl --context="${CTX_CLUSTER2}" wait --for=condition=ready --timeout=5m pod -l app=nse-istio-proxy-responder -n ${NAMESPACE1}

NSE=$(kubectl --context="${CTX_CLUSTER2}" get pods -l app=nse-istio-proxy-responder -n ${NAMESPACE1} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo $NSE

```

**Add ubuntu to cluster #2 for testing**

```bash
cat > ubuntu.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu
  labels:
    app: ubuntu
spec:
  containers:
    - image: ubuntu
      command:
        - "sleep"
        - "604800"
      imagePullPolicy: IfNotPresent
      name: ubuntu 
EOF

kubectl --context="${CTX_CLUSTER2}" apply -n ${NAMESPACE1} -f ./ubuntu.yaml

kubectl --context="${CTX_CLUSTER2}" wait --for=condition=ready --timeout=5m pod -l app=ubuntu -n ${NAMESPACE1}

kubectl --context="${CTX_CLUSTER2}" exec -n ${NAMESPACE1} ubuntu -- apt-get update
kubectl --context="${CTX_CLUSTER2}" exec -n ${NAMESPACE1} ubuntu -- apt-get install -y curl 
 
```

**Check connectivity**

```bash
kubectl --context="${CTX_CLUSTER1}" exec ${NSC} -n ${NAMESPACE2} -ti -c cmd-nsc -- ping -c 4 172.16.1.2

kubectl --context="${CTX_CLUSTER2}" exec ${NSE} -n ${NAMESPACE1} -ti -c nse -- ping -c 4 172.16.1.3

```

**Check requests**

```bash
kubectl --context="${CTX_CLUSTER1}" exec ${NSC} -n ${NAMESPACE2} -c cmd-nsc -- wget workload2.${NAMESPACE1}.svc.cluster.local -O -

kubectl --context="${CTX_CLUSTER2}" exec ubuntu -n ${NAMESPACE1} -- curl -Ss workload1.${NAMESPACE1}.svc.cluster.local

```

## Creanup

```bash
kubectl --context="${CTX_CLUSTER1}" delete ns ${NAMESPACE2}
kubectl --context="${CTX_CLUSTER2}" delete ns ${NAMESPACE1}

```
