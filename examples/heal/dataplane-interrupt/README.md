# Dataplane Interruption

This example shows that NSM not only checks that control plane is fine (NSMgr, Registry, etc), but also catches that data plane is interrupted and performs healing when it's restored.

NSC and NSE are using the `kernel` mechanism to connect with each other.

## Requires

Make sure that you have completed steps from [basic](../../basic) or [memory](../../memory) setup.

## Run

Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a/examples/heal/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

Get nodes exclude control-plane:
```bash
NODE=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}')[0])
```

Create customization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nsc-kernel?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=9b2e8e76fbc7505da8e87ea24bf90ac39f4b6c1a

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
              value: kernel://icmp-responder/nsm-1
        - name: alpine
          securityContext:
            capabilities:
              add: ["NET_ADMIN"]
          image: alpine:3.15.0
          imagePullPolicy: IfNotPresent
          stdin: true
          tty: true
      nodeName: ${NODE}
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
      nodeName: ${NODE}
EOF
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

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=nsc-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -c nsc -- ping -c 4 172.16.1.100
```

Ping from NSE to NSC:
```bash
kubectl exec ${NSE} -n ${NAMESPACE} -- ping -c 4 172.16.1.101
```

Run a pinger process in the background. The pinger will run until it encounters missing packets.
```bash
PINGER_PATH=/tmp/done-${RANDOM}
kubectl exec ${NSC} -n ${NAMESPACE} -c nsc -- sh -c '
  PINGER_PATH=$1; rm -f "$PINGER_PATH"
  seq=0
  ping -i 0.2 172.16.1.100 | while :; do
    read -t 1 line || { echo ping timeout; touch $PINGER_PATH; break; }
    seq1=$(echo $line | sed -n "s/.* seq=\([0-9]\+\) .*/\1/p")
    [ "$seq1" ] || continue
    [ "$seq" -eq "$seq1" ] || { echo missing $((seq1 - seq)) pings; touch $PINGER_PATH; break; }
    seq=$((seq1+1))
  done
' - "$PINGER_PATH" &
sleep 5
kubectl exec ${NSC} -n ${NAMESPACE} -c nsc -- test ! -f /tmp/done || { echo pinger is done; false; }
```

Simulate data plane interruption by shutting down the kernel interface:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -c alpine -- ip link set nsm-1 down
```

Wait until the pinger process stops. This would be an indication that the data plane was temporarily interrupted.
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -c nsc -- sh -c 'timeout 10 sh -c "while ! [ -f \"$1\" ];do sleep 1; done"' - "$PINGER_PATH"
```

Ping from NSC to NSE:
```bash
kubectl exec ${NSC} -n ${NAMESPACE} -c nsc -- ping -c 4 172.16.1.100
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
