

## Requires

- [Load balancer](../nsm_istio/loadbalancer)
- [Interdomain DNS](../nsm_istio/dns)
- [Interdomain spire](../nsm_istio/spire)
- [Interdomain nsm](../nsm_istio/nsm)


Start vl3
```bash
kubectl --kubeconfig=$KUBECONFIG1 create ns ns-vl3
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./vl3-basic
```

Start pods for services and kuma control-plane

```bash
kubectl --kubeconfig=$KUBECONFIG1 apply -f ubuntu.yaml

export CP=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -l name=control-plane --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl --kubeconfig=$KUBECONFIG1 exec -it $CP -c ubuntu -- apt update 
kubectl --kubeconfig=$KUBECONFIG1 exec -it $CP -c ubuntu -- apt install --yes curl net-tools 
export KUMA_CP_ADDRESS=$(kubectl --kubeconfig=$KUBECONFIG1 exec -it $CP -c ubuntu -- ifconfig | grep 'inet 169' | cut -d: -f2 | awk '{print $2}')

kubectl --kubeconfig=$KUBECONFIG1 apply -f ubuntu-1.yaml
kubectl --kubeconfig=$KUBECONFIG2 apply -f ubuntu-2.yaml
```

Run control-plane
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it $CP -c ubuntu -- bash
curl -L https://kuma.io/installer.sh | bash - 

ln -s /kuma-1.7.0/bin/kumactl /usr/local/bin/kumactl 
ln -s /kuma-1.7.0/bin/kuma-cp /usr/local/bin/kuma-cp
ln -s /kuma-1.7.0/bin/kuma-dp /usr/local/bin/kuma-dp 
ln -s /kuma-1.7.0/bin/coredns /usr/local/bin/coredns 
ln -s /kuma-1.7.0/bin/envoy /usr/local/bin/envoy 

KUMA_DP_SERVER_AUTH_TYPE=none kuma-cp run
```



Open new terminal window and start first dataplane
```bash
kubectl --kubeconfig=$KUBECONFIG1 exec -it ubuntu-1 -c ubuntu -- bash

apt update 
apt install --yes curl net-tools redis
curl -L https://kuma.io/installer.sh | bash - 

ln -s /kuma-1.7.0/bin/kumactl /usr/local/bin/kumactl 
ln -s /kuma-1.7.0/bin/kuma-cp /usr/local/bin/kuma-cp
ln -s /kuma-1.7.0/bin/kuma-dp /usr/local/bin/kuma-dp 
ln -s /kuma-1.7.0/bin/coredns /usr/local/bin/coredns 
ln -s /kuma-1.7.0/bin/envoy /usr/local/bin/envoy 

redis-server --port 26379 --daemonize yes
redis-cli -p 26379 set zone local

export IP=$(ifconfig | grep 'inet 169' | cut -d: -f2 | awk '{print $2}')
cat > redis-dataplane.yaml <<EOF
type: Dataplane
mesh: default
name: redis
networking:
  address: {{ IP }}
  inbound:
    - port: 16379
      servicePort: 26379
      tags:
        kuma.io/service: redis
        kuma.io/protocol: tcp
EOF

kuma-dp run \
   --cp-address=https://$KUMA_CP_ADDRESS:5678/ \
   --dataplane-file=redis-dataplane.yaml \
   --dataplane-var IP=$IP
```


Open new terminal window and start second dataplane
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec -it ubuntu-2 -c ubuntu -- bash

apt update 
apt install --yes curl net-tools git
curl -L https://kuma.io/installer.sh | bash - 

ln -s /kuma-1.7.0/bin/kumactl /usr/local/bin/kumactl 
ln -s /kuma-1.7.0/bin/kuma-cp /usr/local/bin/kuma-cp
ln -s /kuma-1.7.0/bin/kuma-dp /usr/local/bin/kuma-dp 
ln -s /kuma-1.7.0/bin/coredns /usr/local/bin/coredns 
ln -s /kuma-1.7.0/bin/envoy /usr/local/bin/envoy 

export IP=$(ifconfig | grep 'inet 169' | cut -d: -f2 | awk '{print $2}')
cat > app-dataplane.yaml <<EOF
type: Dataplane
mesh: default
name: app
networking:
  address: {{ IP }}
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
    port: 9902"
EOF

kuma-dp run \
   --cp-address=https://$KUMA_CP_ADDRESS:5678/ \
   --dataplane-file=app-dataplane.yaml \
   --dataplane-var IP=$IP
```

Open new terminal window to start counter page
```bash
kubectl --kubeconfig=$KUBECONFIG2 exec -it ubuntu-2 -c ubuntu -- bash

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 15
nvm use 15

git clone https://github.com/kumahq/kuma-counter-demo.git
cd kuma-counter-demo
npm install --prefix=app/
npm start --prefix=app/
```

Forward ports to open counter page
```bash
kubectl --kubeconfig=$KUBECONFIG2 port-forward ubuntu-2 5000:5000
```
Go to [locahost:5000](http://localhost:5000) to get counter page.
