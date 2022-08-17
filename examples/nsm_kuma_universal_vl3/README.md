

## Requires

- [Load balancer](../interdomain/loadbalancer)
- [Interdomain DNS](../interdomain/dns)
- [Interdomain spire](../interdomain/spire)
- [Interdomain nsm](../interdomain/nsm)

Start vl3
```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./vl3-dns
```

Start pods for services and kuma control-plane

```bash
kubectl --kubeconfig=$KUBECONFIG1 create ns kuma-demo
kubectl --kubeconfig=$KUBECONFIG2 create ns kuma-demo
kubectl --kubeconfig=$KUBECONFIG1 apply -f control-plane.yaml

export CP=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -n kuma-demo -l name=control-plane --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG1 apply -f redis.yaml
kubectl --kubeconfig=$KUBECONFIG2 apply -f demo-app.yaml
```

Run control-plane
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it -n kuma-demo $CP -c ubuntu -- bash

apt update 
apt install --yes curl net-tools 
curl -L https://kuma.io/installer.sh | VERSION=1.7.0 bash - 

ln -s /kuma-1.7.0/bin/kumactl /usr/local/bin/kumactl 
ln -s /kuma-1.7.0/bin/kuma-cp /usr/local/bin/kuma-cp
ln -s /kuma-1.7.0/bin/kuma-dp /usr/local/bin/kuma-dp 
ln -s /kuma-1.7.0/bin/coredns /usr/local/bin/coredns 
ln -s /kuma-1.7.0/bin/envoy /usr/local/bin/envoy 

kumactl generate tls-certificate --hostname=control-plane-kuma.my-vl3-network --type=server

KUMA_DP_SERVER_AUTH_TYPE=none KUMA_GENERAL_TLS_CERT_FILE=/cert.pem KUMA_GENERAL_TLS_KEY_FILE=/key.pem kuma-cp run
```



Open new terminal window and start first dataplane
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it -n kuma-demo redis -c ubuntu -- bash

apt update 
apt install --yes curl net-tools redis
curl -L https://kuma.io/installer.sh | VERSION=1.7.0 bash - 

ln -s /kuma-1.7.0/bin/kumactl /usr/local/bin/kumactl 
ln -s /kuma-1.7.0/bin/kuma-cp /usr/local/bin/kuma-cp
ln -s /kuma-1.7.0/bin/kuma-dp /usr/local/bin/kuma-dp 
ln -s /kuma-1.7.0/bin/coredns /usr/local/bin/coredns 
ln -s /kuma-1.7.0/bin/envoy /usr/local/bin/envoy 

redis-server --port 26379 --daemonize yes
redis-cli -p 26379 set zone local

cat > redis-dataplane.yaml <<EOF
type: Dataplane
mesh: default
name: redis
networking:
  address: redis.my-vl3-network
  inbound:
    - port: 16379
      servicePort: 26379
      tags:
        kuma.io/service: redis
        kuma.io/protocol: tcp
EOF

kuma-dp run \
   --cp-address=https://control-plane-kuma.my-vl3-network:5678/ \
   --dataplane-file=redis-dataplane.yaml
```


Open new terminal window and start second dataplane
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec -it -n kuma-demo demo-app -c ubuntu -- bash

apt update 
apt install --yes curl net-tools git
curl -L https://kuma.io/installer.sh | VERSION=1.7.0 bash - 

ln -s /kuma-1.7.0/bin/kumactl /usr/local/bin/kumactl 
ln -s /kuma-1.7.0/bin/kuma-cp /usr/local/bin/kuma-cp
ln -s /kuma-1.7.0/bin/kuma-dp /usr/local/bin/kuma-dp 
ln -s /kuma-1.7.0/bin/coredns /usr/local/bin/coredns 
ln -s /kuma-1.7.0/bin/envoy /usr/local/bin/envoy 

cat > app-dataplane.yaml <<EOF
type: Dataplane
mesh: default
name: demo-app
networking:
  address: demo-app.my-vl3-network
  outbound:
    - port: 6379
      tags:
        kuma.io/service: redis
  inbound:
    - port: 15000
      servicePort: 5000
      tags:
        kuma.io/service: app
        kuma.io/protocol: http
  admin:
    port: 9902
EOF

kuma-dp run \
   --cp-address=https://control-plane-kuma.my-vl3-network:5678/ \
   --dataplane-file=app-dataplane.yaml
```

Open new terminal window to start counter page
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec -it -n kuma-demo demo-app -c ubuntu -- bash

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 15
nvm use 15

git clone https://github.com/kumahq/kuma-counter-demo.git
cd kuma-counter-demo
npm install --prefix=app/
REDIS_HOST=redis.my-vl3-network npm start --prefix=app/
```

Forward ports to open counter page
```bash
kubectl --kubeconfig=$KUBECONFIG2 port-forward -n kuma-demo demo-app 5000:5000
```
Go to [locahost:5000](http://localhost:5000) to get counter page.
