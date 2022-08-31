# NSM + Consul + vl3 interdomain example over kind clusters

This example shows how Consul can be used over NSM with vl3. 


## Requires

- [Load balancer](../loadbalancer)
- [Interdomain DNS](../dns)
- [Interdomain spire](../spire)
- [Interdomain nsm](../nsm)


## Run

References:
https://learn.hashicorp.com/tutorials/consul/deployment-guide?in=consul/production-deploy
https://learn.hashicorp.com/tutorials/consul/tls-encryption-secure
https://learn.hashicorp.com/tutorials/consul/service-mesh-with-envoy-proxy?in=consul/developer-mesh

Load custom images with preinstalled consul and envoy onto clusters:
```bash
docker build -t consul-client:latest ./examples/interdomain/nsm_consul_vl3/dockerfile/
kind load docker-image consul-client:latest  --name cluster-1
kind load docker-image consul-client:latest  --name cluster-2
```

Start vl3, install Consul control plane and counting service on the first cluster
```bash
kubectl --kubeconfig=$KUBECONFIG1 create ns ns-nsm-consul-vl3
kubectl --kubeconfig=$KUBECONFIG1 apply -k ./examples/interdomain/nsm_consul_vl3/cluster1
```
Install Consul dashboard service on the second cluster
```bash
kubectl --kubeconfig=$KUBECONFIG2 create ns ns-nsm-consul-vl3
kubectl --kubeconfig=$KUBECONFIG2 apply -k ./examples/interdomain/nsm_consul_vl3/cluster2
```

Wait for pods to be ready:
```bash
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=nse-vl3-vpp -n ns-nsm-consul-vl3
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l app=vl3-ipam -n ns-nsm-consul-vl3
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod -l name=control-plane -n ns-nsm-consul-vl3
kubectl --kubeconfig=$KUBECONFIG1 wait --for=condition=ready --timeout=5m pod counting -n ns-nsm-consul-vl3
kubectl --kubeconfig=$KUBECONFIG2 wait --for=condition=ready --timeout=5m pod dashboard -n ns-nsm-consul-vl3
```

```bash
export CP=$(kubectl --kubeconfig=$KUBECONFIG1 get pods -n ns-nsm-consul-vl3 -l name=control-plane --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
```

(On the control plane pod) Generate the gossip encryption key:
```bash
ENCRYPTION_KEY=$(kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it ${CP} -c ubuntu -- consul keygen)
```

(On the control plane pod) Get CP vl3 IP
```bash
CP_IP_VL3_ADDRESS=$(kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it ${CP} -c ubuntu -- ifconfig nsm-1 | grep -Eo 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 6-)
```

(On the control plane pod) Initialize Consul CA
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it ${CP} -c ubuntu -- consul tls ca create
```

(On the control plane pod) Create the server certificates
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it ${CP} -c ubuntu -- consul tls cert create -server -dc dc1
```

Update control plane configuration. Use here the saved encryption key and CP vl3 IP address
```bash
cat > consul.hcl <<EOF
data_dir = "/opt/consul"
datacenter = "dc1"
encrypt = "${ENCRYPTION_KEY}"
tls {
  defaults {
    ca_file = "consul-agent-ca.pem"
    cert_file = "dc1-server-consul-0.pem"
    key_file = "dc1-server-consul-0-key.pem"
    verify_incoming = true
    verify_outgoing = true
  }
  internal_rpc {
    verify_server_hostname = true
  }
}
auto_encrypt {
  allow_tls = true
}
acl {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
}
EOF
```

```bash
cat > server.hcl <<EOF
server = true
bootstrap_expect = 1
bind_addr = "${CP_IP_VL3_ADDRESS}"
connect {
  enabled = true
}

addresses {
  grpc = "127.0.0.1"
}
ports {
  grpc  = 8502
}
EOF
```

Copy configs into the Control plane Ubuntu container
```bash
kubectl --kubeconfig=$KUBECONFIG1 cp consul.hcl ns-nsm-consul-vl3/${CP}:/etc/consul.d/
kubectl --kubeconfig=$KUBECONFIG1 cp server.hcl ns-nsm-consul-vl3/${CP}:/etc/consul.d/
```

(On the control plane pod) Validate the configuration 
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it ${CP} -c ubuntu -- sudo consul validate /etc/consul.d/
```

(On the control plane pod) Start Consul CP
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec ${CP} -c ubuntu -- /bin/bash -c 'consul agent -config-dir=/etc/consul.d/  1>/dev/null 2>&1 &'
```

Check that Consul Server has started:
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec ${CP} -c ubuntu -- consul members
```

(On the counting pod) Set the counting  and control plane pods vl3 IP
```bash
COUNTING_IP_VL3_ADDRESS=$(kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- ifconfig nsm-1 | grep -Eo 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 6-)
```
Copy certificates from the Control plane into Counting Pod
```bash
kubectl --kubeconfig=$KUBECONFIG1 cp  ns-nsm-consul-vl3/${CP}:consul-agent-ca.pem consul-agent-ca.pem
kubectl --kubeconfig=$KUBECONFIG1 cp  ns-nsm-consul-vl3/${CP}:consul-agent-ca-key.pem consul-agent-ca-key.pem

kubectl --kubeconfig=$KUBECONFIG1 cp consul-agent-ca.pem ns-nsm-consul-vl3/counting:/etc/consul.d
kubectl --kubeconfig=$KUBECONFIG1 cp consul-agent-ca-key.pem ns-nsm-consul-vl3/counting:/etc/consul.d
```

Update countign configuration. Use here the saved encryption key and the Counting service pod vl3 IP address
```bash
cat > consul-counting.hcl <<EOF
data_dir = "/opt/consul"
encrypt = "${ENCRYPTION_KEY}"
tls {
  defaults {
    ca_file = "/etc/consul.d/consul-agent-ca.pem"
    verify_incoming = false
    verify_outgoing = true
  }
  internal_rpc {
    verify_server_hostname = true
  }
}
auto_encrypt {
  tls = true
}
acl {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
}
bind_addr = "${COUNTING_IP_VL3_ADDRESS}"
connect {
  enabled = true
}
addresses {
  grpc = "127.0.0.1"
}
ports {
  grpc  = 8502
}
EOF
```
Copy configs into the Counting pod:
```bash
kubectl --kubeconfig=$KUBECONFIG1 cp consul-counting.hcl ns-nsm-consul-vl3/counting:/etc/consul.d/
```

(On the counting pod) Validate the configuration 
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- sudo consul validate /etc/consul.d/
```

Create script to run Consul as daemon:
```bash
cat > consul.service <<EOF
[Unit]
Description=Consul
Documentation=https://www.consul.io/

[Service]
ExecStart=/usr/bin/consul agent -join ${CP_IP_VL3_ADDRESS} -config-dir=/etc/consul.d/ 
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

Copy script into Counting Pod:
```bash
kubectl --kubeconfig=$KUBECONFIG1 cp consul.service ns-nsm-consul-vl3/counting:/etc/systemd/system/consul.service
```

(On the counting pod) Start Consul agent
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- sudo systemctl daemon-reload
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- sudo systemctl start consul.service 
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- sudo systemctl enable consul.service 
```

Check that Consul Counting client has started:
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec counting -c ubuntu -- consul members
```

Create the counting service definition
```bash
cat > counting.hcl <<EOF
service {
  name = "counting"
  id = "counting-1"
  port = 9001

  connect {
    sidecar_service {}
  }

  check {
    id       = "counting-check"
    http     = "http://localhost:9001/health"
    method   = "GET"
    interval = "1s"
    timeout  = "1s"
  }
}
EOF
```

Copy into Counting Pod:
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- mkdir service
kubectl --kubeconfig=$KUBECONFIG1 cp counting.hcl ns-nsm-consul-vl3/counting:/service
```

(On the counting pod) Register the service with Consul
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- consul services register /service/counting.hcl 
```
You should see `Registered service: counting'

Create script to run envoy service in a background:
```bash
cat > consul-envoy.service <<EOF
[Unit]
Description=Consul
Documentation=https://www.consul.io/

[Service]
ExecStart=/usr/bin/consul connect envoy -sidecar-for counting-1 -admin-bind localhost:19001 
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 cp consul-envoy.service ns-nsm-consul-vl3/counting:/etc/systemd/system/consul-envoy.service
```
```bash
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- sudo systemctl daemon-reload 
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- sudo systemctl start consul-envoy.service 
kubectl --kubeconfig=$KUBECONFIG1 -n ns-nsm-consul-vl3 exec -it counting -c ubuntu -- sudo systemctl enable consul-envoy.service 
```

(On the dashboard pod) Set the pod vl3 IP
```bash
DASHBOARD_IP_VL3_ADDRESS=$(kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- ifconfig nsm-1 | grep -Eo 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| cut -c 6-)
```

(On the dashboard pod) Copy certificates from the Control plane into Dashboard Pod
```bash
kubectl --kubeconfig=$KUBECONFIG2 cp consul-agent-ca.pem ns-nsm-consul-vl3/dashboard:/etc/consul.d
kubectl --kubeconfig=$KUBECONFIG2 cp consul-agent-ca-key.pem ns-nsm-consul-vl3/dashboard:/etc/consul.d
```
(On the dashboard pod) Update dashboard configuration. Use here the saved encryption key and the Dashboard service pod vl3 IP address
```bash
cat > consul-dashboard.hcl <<EOF
encrypt = "${ENCRYPTION_KEY}"
data_dir = "/opt/consul"
tls {
  defaults {
    ca_file = "/etc/consul.d/consul-agent-ca.pem"
    verify_incoming = false
    verify_outgoing = true
  }
  internal_rpc {
    verify_server_hostname = true
  }
}
datacenter = "dc1"
auto_encrypt {
  tls = true
}
acl {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
}
bind_addr = "${DASHBOARD_IP_VL3_ADDRESS}"
connect {
  enabled = true
}
addresses {
  grpc = "127.0.0.1"
}
ports {
  grpc  = 8502
}
EOF
```

Copy config into the Counting pod Ubuntu container
```bash
kubectl --kubeconfig=$KUBECONFIG2 cp consul-dashboard.hcl ns-nsm-consul-vl3/dashboard:/etc/consul.d/
```

(On the dashboard pod) Validate the configuration 
```bash
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- sudo consul validate /etc/consul.d/
```

Create script to run Consul dashboard client in background: 
```bash
cat > consul.service <<EOF
[Unit]
Description=Consul
Documentation=https://www.consul.io/

[Service]
ExecStart=/usr/bin/consul agent -join ${CP_IP_VL3_ADDRESS} -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```
Copy into the dashboard pod:
```bash
kubectl --kubeconfig=$KUBECONFIG2 cp consul.service ns-nsm-consul-vl3/dashboard:/etc/systemd/system/consul.service
```
Start service:
```bash
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- sudo systemctl daemon-reload 
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- sudo systemctl start consul.service 
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- sudo systemctl enable consul.service 
```

Create the dashboard service definition:
```bash
cat > dashboard.hcl <<EOF
service {
  name = "dashboard"
  port = 9002

  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "counting"
            local_bind_port  = 5000
          }
        ]
      }
    }
  }

  check {
    id       = "dashboard-check"
    http     = "http://localhost:9002/health"
    method   = "GET"
    interval = "1s"
    timeout  = "1s"
  }
}
EOF
```

Copy into Dashboard Pod:
```bash
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- mkdir service
kubectl --kubeconfig=$KUBECONFIG2 cp dashboard.hcl ns-nsm-consul-vl3/dashboard:/service
```

(On the dashboard pod) Register the service with Consul
```bash
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- consul services register /service/dashboard.hcl
```
You should see 'Registered service: dashboard'

Create script to run envoy service and copy into the dashboard pod:
```bash
cat > consul-envoy.service <<EOF
[Unit]
Description=Consul
Documentation=https://www.consul.io/

[Service]
ExecStart=/usr/bin/consul connect envoy -sidecar-for dashboard
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

```bash
kubectl --kubeconfig=$KUBECONFIG2 cp consul-envoy.service ns-nsm-consul-vl3/dashboard:/etc/systemd/system/consul-envoy.service
```
Start service:
```bash
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- sudo systemctl daemon-reload 
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- sudo systemctl start consul-envoy.service 
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 exec -it dashboard -c ubuntu -- sudo systemctl enable consul-envoy.service 
```

Port-forward the dashboard pod
```bash
kubectl --kubeconfig=$KUBECONFIG2 -n ns-nsm-consul-vl3 port-forward dashboard 9002:9002 &
```

In your browser open localhost:9002 and verify the application works!
Also you can run this to check that it works:
```bash
result=`curl --include --no-buffer --connect-timeout 20 -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Host: 127.0.0.1:9002" -H "Origin: http://127.0.0.1:9002" -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" -H "Sec-WebSocket-Version: 13" http://127.0.0.1:9002/socket.io/?EIO=3&transport=websocket`
echo ${result} | grep  -o 'Unreachable'
```

##Cleanup

```bash
pkill -f "port-forward"
kubectl --kubeconfig=$KUBECONFIG1 delete -n ns-nsm-consul-vl3 -k ./examples/interdomain/nsm_consul_vl3/cluster1
kubectl --kubeconfig=$KUBECONFIG2 delete -n ns-nsm-consul-vl3 -k ./examples/interdomain/nsm_consul_vl3/cluster2
```


