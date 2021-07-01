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

for ((i = 1; i <= PASS_COUNT; i++))
do
  f="passthrough-${i}"
  NAME="nse-passthrough-${i}"
  LABELS="app:passthrough-${i}"
  if ((i == 4))
  then
    f="nse-firewall"
    NAME="acl-filter"
    LABELS="app:firewall"
    VOLUME_PATCH="- config-patch.yaml"
  fi
  if [ -d "${f}" ]
  then
    rm -r "${f}"
  fi
  mkdir "${f}"
  cd "${f}" || exit
  cat > kustomization.yaml <<EOF
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
if((i == 4))
then
cat > config-patch.yaml <<EOF
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
  cat > patch-nse-firewall-vpp.yaml <<EOF
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
  cd ../
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
            - name: NSM_CIDR_PREFIX
              value: 172.16.1.100/31    
            - name: NSM_SERVICE_NAME
              value: "nse-composition"  
            - name: NSM_REGISTER_SERVICE
              value: "false"  
            - name: NSM_LABELS
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
        srcprefix:
          address:
            af: 0
            un:
              xxx_uniondata:
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
          len: 0
        dstprefix:
          address:
            af: 0
            un:
              xxx_uniondata:
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
          len: 0
        proto: 1
        srcportoricmptypefirst: 0
        srcportoricmptypelast: 65535
        dstportoricmpcodefirst: 0
        dstportoricmpcodelast: 65535
        tcpflagsmask: 0
        tcpflagsvalue: 0
      allow tcp8080:
        ispermit: 1
        srcprefix:
          address:
            af: 0
            un:
              xxx_uniondata:
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
          len: 0
        dstprefix:
          address:
            af: 0
            un:
              xxx_uniondata:
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
              - 0
          len: 0
        proto: 6
        srcportoricmptypefirst: 0
        srcportoricmptypelast: 65535
        dstportoricmpcodefirst: 8080
        dstportoricmpcodelast: 8080
        tcpflagsmask: 0
        tcpflagsvalue: 0
EOF
```

Deploy ConfigMap
```bash
kubectl apply -f config-file.yaml
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
kubectl exec -it ${NSC} -n ${NAMESPACE} -- wget -O /dev/null --timeout 5 "172.16.1.100:8080"
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