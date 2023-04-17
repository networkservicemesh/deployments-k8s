## Setup DNS

This example shows how to configure k8s cluster and docker container to know each other.

## Run

1. Expose kube-dns service

```bash
kubectl expose service kube-dns -n kube-system --port=53 --target-port=53 --protocol=TCP --name=exposed-kube-dns --type=LoadBalancer
```

Wait for setting externalIP:
```bash
kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'
```

Get and store externalIP of the coredns
```bash
ipk8s=$(kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}')
if [[ $ipk8s == *"no value"* ]]; then
    $ipk8s=$(kubectl get services exposed-kube-dns -n kube-system -o go-template='{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}')
    $ipk8s=$(dig +short $ipk8s | head -1)
fi
# if IPv6
if [[ $ipk8s =~ ":" ]]; then $ipk8s=[$ipk8s]; fi

echo Selected externalIP: $ipk8s
[[ ! -z $ipk8s ]]
```

2. Get an externalIP of the docker container:
```bash
ipdock=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nsc-simple-docker)
# if IPv6
if [[ $ipdock =~ ":" ]]; then $ipdock=[$ipdock]; fi

echo Selected dockerIP: $ipdock
[[ ! -z $ipdock ]]
```

3. Update k8s CoreDNS configmap:

```bash
kubectl apply -f - <<EOF
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
        k8s_external k8s.nsm
        prometheus :9153
        forward . /etc/resolv.conf
        loop
        reload 5s
    }
    docker.nsm:53 {
        log
        forward . ${ipdock}:53 {
            force_tcp
        }
        reload 5s
    }
EOF
```

Restart CoreDNS pods to immediately use the config map:
```bash
kubectl rollout restart -n kube-system deployment/coredns
```

4. Start docker CoreDNS

Save the initial `resolv.conf` in a separate file:
```bash
docker exec -d -i nsc-simple-docker cp /etc/resolv.conf /etc/resolv_init.conf
```

Add an entry to `resolv.conf` with a coredns address.
Use a custom address to reduce the chance of it being used (default is 127.0.0.1)
```bash
docker exec -d -i nsc-simple-docker sh -c "echo 'nameserver 127.0.1.1' > /etc/resolv.conf"
```

Create coredns config file:
```bash
cat > coredns-config << EOF
.:53 {
    bind 127.0.1.1
    log
    errors
    ready
    file dnsentries.db
    forward . /etc/resolv_init.conf {
        max_concurrent 1000
    }
    loop
    reload 5s
}
k8s.nsm:53 {
    bind 127.0.1.1
    log
    forward . ${ipk8s}:53 {
        force_tcp
    }
    reload 5s
}
EOF
```

Add a custom dns entry to resolve the spire-server:
```bash
cat > dnsentries.db << EOF
@       3600 IN SOA docker.nsm. . (
                                2017042745 ; serial
                                7200       ; refresh (2 hours)
                                3600       ; retry (1 hour)
                                1209600    ; expire (2 weeks)
                                3600       ; minimum (1 hour)
                                )
spire-server.spire.docker.nsm   IN      A    ${ipdock}
EOF
```

```bash
docker cp coredns-config nsc-simple-docker:/
```

```bash
docker cp dnsentries.db nsc-simple-docker:/
```

Run coredns with this config:
```bash
docker exec -d nsc-simple-docker coredns -conf coredns-config
```

## Cleanup

```bash
kubectl delete service -n kube-system exposed-kube-dns
```
```bash
rm coredns-config dnsentries.db
```
