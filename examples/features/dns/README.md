# Alpine requests for CoreDNS service

This example demonstrates how an external client configures DNS from the connected endpoint. 
Note: NSE provides DNS by itself. Also, NSE could provide configs for any other external DNS servers(that are not located as sidecar with NSE).

## Requires

Make sure that you have completed steps from [features](../)

## Run

Create test namespace:
```bash
kubectl create ns ns-dns
```

Get all available nodes to deploy:
```bash
NODES=($(kubectl get nodes -o go-template='{{range .items}}{{ if not .spec.taints  }}{{index .metadata.labels "kubernetes.io/hostname"}} {{end}}{{end}}'))
```

Create dnsutils deployment and set `nodeName` to the first node:
```bash
cat > dnsutils.yaml <<EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
  annotations:
    networkservicemesh.io: kernel://dns/nsm-1
  labels:
    app: dnsutils
    "spiffe.io/spiffe-id": "true"
spec:
  containers:
  - name: dnsutils
    image: k8s.gcr.io/e2e-test-images/jessie-dnsutils:1.3
    imagePullPolicy: IfNotPresent
    stdin: true
    tty: true
  nodeName: ${NODES[0]}
EOF
```

Add to nse-kernel the corends container and set `nodeName` it to the second node:
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
            value: "dns"
          - name: NSM_REGISTER_SERVICE
            value: "false"
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
      nodeName: ${NODES[1]}
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
EOF
```

Deploy alpine and nse
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/features/dns?ref=562c4f9383ab2a2526008bd7ebace8acf8b18080
```

Wait for applications ready:
```bash
kubectl wait --for=condition=ready --timeout=5m pod dnsutils -n ns-dns
```
```bash
kubectl wait --for=condition=ready --timeout=5m pod -l app=nse-kernel -n ns-dns
```

Find NSC and NSE pods by labels:
```bash
NSC=$(kubectl get pods -l app=dnsutils -n ns-dns --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```
```bash
NSE=$(kubectl get pods -l app=nse-kernel -n ns-dns --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

Ping from dnsutils to NSE by domain name:
```bash
kubectl exec ${NSC} -c dnsutils -n ns-dns -- nslookup -norec -nodef my.coredns.service
```
```bash
kubectl exec ${NSC} -c dnsutils -n ns-dns -- ping -c 4 my.coredns.service
```

Validate that default DNS server is working:
```bash
kubectl exec ${NSC} -c dnsutils -n ns-dns -- nslookup kubernetes.default
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-dns
```
