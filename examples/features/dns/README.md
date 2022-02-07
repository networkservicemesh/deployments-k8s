# Alpine requests for CoreDNS service

This example demonstrates how an external client configures DNS from the connected endpoint. 
Note: NSE provides DNS by itself. Also, NSE could provide configs for any other external DNS servers(that are not located as sidecar with NSE).

## Requires

Make sure that you have completed steps from [features](../)

## Run

1. Create test namespace:
```bash
NAMESPACE=($(kubectl create -f https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/namespace.yaml)[0])
NAMESPACE=${NAMESPACE:10}
```

2. Get all available nodes to deploy:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
```

3. Create dnsutils deployment and set `nodeSelector` to the first node:
```bash
cat > dnsutils.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
  annotations:
    networkservicemesh.io: kernel://my-coredns-service/nsm-1
  labels:
    app: dnsutils
    "spiffe.io/spiffe-id": "true"
spec:
  containers:
  - name: dnsutils
    image: gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
    imagePullPolicy: IfNotPresent
    stdin: true
    tty: true
  nodeSelector:
    kubernetes.io/hostname: ${NODES[0]}
EOF
```


4. Add to nse-kernel the corends container and set `nodeSelector` it to the second node:
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
          - name: NSM_SERVICE_NAMES
            value: my-coredns-service
          - name: NSM_CIDR_PREFIX
            value: 172.16.1.100/31
          - name: NSM_DNS_CONFIGS
            value: "[{\"dns_server_ips\": [\"172.16.1.100\"], \"search_domains\": [\"my.coredns.service\"]}]"
      - name: coredns
        image: coredns/coredns:1.8.3
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
      nodeSelector:
        kubernetes.io/hostname: ${NODES[1]}
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
EOF
```

5. Create kustomization file:
```bash
cat > kustomization.yaml <<EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ${NAMESPACE}

bases:
- https://github.com/networkservicemesh/deployments-k8s/apps/nse-kernel?ref=da0228654084085b3659ed6b519f66f44b6796ce

resources:
- dnsutils.yaml
- https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/da0228654084085b3659ed6b519f66f44b6796ce/examples/features/dns/coredns-config-map.yaml

patchesStrategicMerge:
- patch-nse.yaml
EOF
```

6. Deploy alpine and nse
```bash
kubectl apply -k .
```

7. Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod dnsutils -n ${NAMESPACE}
```
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ${NAMESPACE}
```

8. Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=dnsutils -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ${NAMESPACE} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

9. Ping from dnsutils to NSE by domain name:
```bash
kubectl exec ${NSC} -c dnsutils -n ${NAMESPACE} -- nslookup -norec -nodef my.coredns.service
```
```bash
kubectl exec ${NSC} -c dnsutils -n ${NAMESPACE} -- ping -c 4 my.coredns.service
```

10. Validate that default DNS server is working:
```bash
kubectl exec ${NSC} -c dnsutils -n ${NAMESPACE} -- nslookup kubernetes.default
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ${NAMESPACE}
```
