# Test NSE composition

This example demonstrates a more complex Network Service, where we chain three passthrough and one ACL Filtering NS endpoints.
It demonstrates how NSM allows for service composition (chaining).
It involves a combination of kernel and memif mechanisms, as well as VPP enabled endpoints.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f ../namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Register namespace in `spire` server:
```bash
kubectl exec -n spire spire-server-0 -- \
/opt/spire/bin/spire-server entry create \
-spiffeID spiffe://example.org/ns/${NAMESPACE}/sa/default \
-parentID spiffe://example.org/ns/spire/sa/spire-agent \
-selector k8s:ns:${NAMESPACE} \
-selector k8s:sa:default
```

Select node to deploy NSC and NSE:
```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
```

Create Passthrough and firewall NSE configurations:
```bash
PASS_COUNT=4
PASS_CFG=""
NAME=""
LABELS=""
VOLUME_PATCH=""
NS=""

for ((i = 1; i <= PASS_COUNT; i++))
do
  f="passthrough-${i}"
  NAME="nse-passthrough-${i}"
  LABELS="app:passthrough-${i}"
  if ((i == PASS_COUNT))
  then
    f="nse-firewall"
    NAME="acl-filter"
    LABELS="app:firewall"
    VOLUME_PATCH="- config-patch.yaml"
    NS="
    - source_selector:
        app: firewall${NS}
      routes:
        - destination_selector:
            app: gateway
    - routes:
        - destination_selector:
            app: firewall"
  else
    NS="${NS}
      routes:
        - destination_selector:
            app: passthrough-${i}
    - source_selector:
        app: passthrough-${i}"
  fi
  if [ -d "${f}" ]
  then
    rm -r "${f}"
  fi
  mkdir "${f}"
  cat > "${f}"/kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
- ../../../../apps/nse-firewall-vpp
patchesStrategicMerge:
- patch-nse-firewall-vpp.yaml
${VOLUME_PATCH}
patches:
- target:
    kind: Deployment
    name: nse-firewall-vpp
  patch: |-  
    - op: replace  
      path: /metadata/name
      value: ${NAME}
EOF
if((i == PASS_COUNT))
then
cat > "${f}"/config-patch.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-firewall-vpp
spec:
  template:    
    spec:
      containers:
        - name: nse  
          volumeMounts:
            - mountPath: /etc/vppagent-firewall/config.yaml
              subPath: config.yaml
              name: vppagent-firewall-config-volume
      volumes:
        - name: vppagent-firewall-config-volume
          configMap:
            name: vppagent-firewall-config-file
EOF
fi
  cat > "${f}"/patch-nse-firewall-vpp.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-firewall-vpp
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSM_SERVICE_NAME
              value: "nse-composition"
            - name: NSM_LABELS
              value: ${LABELS}
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF
  PASS_CFG="${PASS_CFG}- ./${f}"
  if (( i < PASS_COUNT ))
  then
    PASS_CFG+=$'\n'
  fi
done
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NAMESPACE}

bases:
- config-file.yaml
- ../../../apps/nsc-kernel
- ../../../apps/nse-kernel
${PASS_CFG}

patchesStrategicMerge:
- patch-nsc.yaml
- patch-nse.yaml
EOF
```

Create NSC patch:
```bash
cat > patch-nsc.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsc-kernel
spec:
  template:
    spec:
      containers:
        - name: nsc
          env:
            - name: NSM_NETWORK_SERVICES
              value: kernel://nse-composition/nsm-1
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF
```

Create NSE patch:
```bash
cat > patch-nse.yaml <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nse-kernel
spec:
  template:
    spec:
      containers:
        - name: nse
          env:
            - name: NSE_CIDR_PREFIX
              value: 172.16.1.100/31
            - name: NSE_SERVICE_NAME
              value: "nse-composition"
            - name: NSE_REGISTER_SERVICE
              value: "false"
            - name: NSE_LABELS
              value: "app:gateway"
        - name: nginx
          image: networkservicemesh/nginx
          imagePullPolicy: IfNotPresent
      nodeSelector:
        kubernetes.io/hostname: ${NODE}
EOF                                                                                        
```

Create ConfigMap
```bash
cat > config-file.yaml <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vppagent-firewall-config-file
  namespace: ${NAMESPACE}
data:
  config.yaml: |
    aclrules:
      allow icmp:
        ispermit: 1
        proto: 1
        srcportoricmptypelast: 65535
        dstportoricmpcodelast: 65535
      allow tcp8080:
        ispermit: 1
        proto: 6
        srcportoricmptypelast: 65535
        dstportoricmpcodefirst: 8080
        dstportoricmpcodelast: 8080
      forbid tcp80:
        proto: 6
        srcportoricmptypelast: 65535
        dstportoricmpcodefirst: 80
        dstportoricmpcodelast: 80
EOF
```

Create nse-composition Network Serivice
```bash
cat > nse-composition-ns.yaml <<EOF
---
apiVersion: networkservicemesh.io/v1
kind: NetworkService
metadata:
  name: nse-composition
  namespace: nsm-system
spec:
  payload: ETHERNET
  name: nse-composition
  matches:${NS}
EOF
```

Deploy NS configuration
```bash
kubectl create -f ./nse-composition-ns.yaml
```

Deploy NSC and NSE:
```bash
kubectl apply -k .
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel -n ${NAMESPACE}
```

Find nsc and nse pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- ping -c 4 172.16.1.100
```

Check TCP Port 8080 on NSE is accessible to NSC
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- wget -O /dev/null --timeout 5 "172.16.1.100:8080"
```

Check TCP Port 80 on NSE is inaccessible to NSC
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -- wget -O /dev/null --timeout 5 "172.16.1.100:80" || echo "port :80 is unavailable"
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 172.16.1.101
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```