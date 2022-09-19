Next experiments were made:

Prepare to experiment:
```bash
WEB=web-659544f5f7-ks22r
PROXY=proxy-web-659544f5f7-ks22r

WEB_LOCAL=web-local-67bfcd4d9c-z6fnh
PROXY_LOCAL=proxy-web-local-67bfcd4d9c-z6fnh

export KUBECONFIG1=/tmp/config1
export KUBECONFIG2=/tmp/config2
export KUBECONFIG=$KUBECONFIG1
export KUBECONFIG=$KUBECONFIG2

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
kubectl krew install sniff
export KUBECONFIG=$KUBECONFIG2
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c web-svc -- /bin/sh -c 'apt-get install curl'
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'apk add curl'

kubectl exec -it $PROXY_LOCAL -n ns-nsm-linkerd -c nse -- /bin/sh -c 'apk add curl iptables'

kubectl exec -it $PROXY -n ns-nsm-linkerd -c nse -- /bin/sh -c 'apk add curl iptables'

export KUBECONFIG=$KUBECONFIG1
kubectl exec -it $WEB -n ns-nsm-linkerd -c web-svc -- /bin/sh -c 'apt-get install curl'
kubectl exec -it $WEB -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'apk add curl'
```
  
Get dump for wireshark with sniff. Run in different terminal
```bash
# local 2
mkdir sniff_dump_greetint_on_proxy_local
# local 3
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_greetint_on_proxy_local/proxy-local-linkerd.pcap
```
test with DNS (now it failes, but should work:
```bash
export KUBECONFIG=$KUBECONFIG2
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c web-svc -- /bin/sh -c 'curl -v -H "Connection: close" greeting.ns-nsm-linkerd:9080'
```

To check how it should work, run and get dump with sniff:
```bash
export KUBECONFIG=$KUBECONFIG2
kubectl exec -it $PROXY_LOCAL -n ns-nsm-linkerd -c web-svc -- /bin/sh -c 'curl -v -H "Connection: close" greeting.ns-nsm-linkerd:9080'
```

Run ifconfig to get NSM interface name and NSM IP address to use. Mostly 172.16.1.2 is used:
```bash
kubectl exec -it $PROXY_LOCAL -n ns-nsm-linkerd -c nse -- ifconfig
PROXY_LOCAL_NSM_ADDR=172.16.1.2
NSM=nsm-linker-9090
```
Get Cluster IP, Pod IP for PROXY_LOCAL and greeting pod:
```bash
GREET_CLUSTER_IP=10.96.126.33```
```

Check connectivity with NSM address:
Run
```bash
# terminal 2
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_web_local_to_clusterip/proxy-local-linkerd.pcap

# terminal 1
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v  ${PROXY_LOCAL_NSM_ADDR}:9080'
```

Check connectivity with cluster IP 10.96.126.33:9080 (to greeting)
```bash
# local 2
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_web_local_to_clusterip/proxy-local-linkerd.pcap

export KUBECONFIG=$KUBECONFIG2
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" ${GREET_CLUSTER_IP}:9080'
```

Experiments:
exp 0 (no iprules)
$ kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" 172.16.1.2:9080'
* Result:  
* Trying 172.16.1.2:9080...
* Connected to 172.16.1.2 (172.16.1.2) port 9080 (#0)
> GET / HTTP/1.1
> Host: 172.16.1.2:9080
> User-Agent: curl/7.83.1
> Accept: */*
> Connection: close
>
* Empty reply from server
* Closing connection 0
  curl: (52) Empty reply from server
  command terminated with exit code 52

kubectl exec -it $PROXY_LOCAL -n ns-nsm-linkerd -c nse -- /bin/sh
Add Iptables (they don't work):
---
iptables -t nat -N NSM_PREROUTE
iptables -t nat -A NSM_PREROUTE -j PROXY_INIT_REDIRECT
iptables -t nat -I PREROUTING 1 -p tcp -i nsm-linkerd -j NSM_PREROUTE
iptables -t nat -N NSM_OUTPUT
iptables -t nat -A NSM_OUTPUT -j DNAT --to-destination 10.96.126.33
iptables -t nat -A OUTPUT -p tcp -s 0.0.0.0 -j NSM_OUTPUT
iptables -t nat -N NSM_POSTROUTING
iptables -t nat -A NSM_POSTROUTING -j SNAT --to-source 172.16.1.3
iptables -t nat -D POSTROUTING -p tcp -o nsm-linkerd -j NSM_POSTROUTING

**Curl result**
```bash
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" 172.16.1.2:9080'
```

*   Trying 172.16.1.2:9080...
* Connected to 172.16.1.2 (172.16.1.2) port 9080 (#0)
> GET / HTTP/1.1
> Host: 172.16.1.2:9080
> User-Agent: curl/7.83.1
> Accept: */*
> Connection: close
>
* Recv failure: Connection reset by peer
* Closing connection 0
  curl: (56) Recv failure: Connection reset by peer
  command terminated with exit code 56


**exp2**
delete applied chain:
iptables -t nat -D POSTROUTING -p tcp -o nsm-linkerd -j NSM_POSTROUTING
iptables -t nat --flush NSM_POSTROUTING
iptables -t nat -X NSM_POSTROUTING

iptables -t nat -N NSM_POSTROUTING
iptables -t nat -A NSM_POSTROUTING -j SNAT --to-source 172.16.1.3
iptables -t nat -A POSTROUTING -p tcp -o nsm-linkerd -j NSM_POSTROUTING

kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" 172.16.1.2:9080'
*   Trying 172.16.1.2:9080...
* Connected to 172.16.1.2 (172.16.1.2) port 9080 (#0)
> GET / HTTP/1.1
> Host: 172.16.1.2:9080
> User-Agent: curl/7.83.1
> Accept: */*
> Connection: close
>
* Empty reply from server
* Closing connection 0
  curl: (52) Empty reply from server
  command terminated with exit code 52

**exp3**
delete Linkerd loopback chain rule:

iptables -t nat -D PROXY_INIT_OUTPUT -o lo -m comment --comment "proxy-init/ignore-loopback/1663224390" -j RETURN

iptables -t nat -I PROXY_INIT_OUTPUT 2 -o lo -m comment --comment "proxy-init/ignore-loopback/1663224390" -j RETURN


**exp4**

delete NSM_OUTPUT chain
iptables -t nat -D NSM_OUTPUT -j DNAT --to-destination 10.96.126.33
iptables -t nat --flush NSM_OUTPUT
iptables -t nat -D OUTPUT -s 0.0.0.0/32 -p tcp -j NSM_OUTPUT
iptables -t nat -X NSM_OUTPUT

--destination

iptables -t nat -S NSM_PREROUTE
iptables -t nat -A NSM_PREROUTE -d 10.96.126.33
iptables -t nat -D NSM_PREROUTE -j PROXY_INIT_REDIRECT
iptables -t nat -I PREROUTING 1 -p tcp -i nsm-linkerd -j NSM_PREROUTE
iptables -t nat -D PREROUTING -i nsm-linkerd -p tcp -j NSM_PREROUTE
iptables -t nat -D NSM_PREROUTE -d 10.96.126.33

iptables -t nat -A NSM_PREROUTE --to-destination 10.96.126.33

iptables -t nat -I NSM_PREROUTE 1 -d 10.96.126.33

cluster to cluster
curl 172.16.1.2:9080
curl clusterIP



iptables -t nat -N NSM_PREROUTE
iptables -t nat -A NSM_PREROUTE -p tcp -j DNAT --to-destination 10.96.126.33
iptables -t nat -A NSM_PREROUTE -p tcp -j PROXY_INIT_REDIRECT
iptables -t nat -I PREROUTING 1 -p tcp -i nsm-linkerd -j NSM_PREROUTE


iptables -t nat -N NSM_POSTROUTING
iptables -t nat -A NSM_POSTROUTING -p tcp -j SNAT --to-source 172.16.1.2

iptables -t nat -D POSTROUTING -p tcp -o nsm-linkerd -j NSM_POSTROUTING



iptables -t nat -D NSM_POSTROUTING -j SNAT --to-source 172.16.1.3
iptables -t nat -D NSM_PREROUTE -j PROXY_INIT_REDIRECT

exp 6
iptables -t nat -D PREROUTING -p tcp -i nsm-linkerd -j NSM_PREROUTE
iptables -t nat -I PREROUTING 1 -p tcp -i nsm-linkerd -d 172.16.1.2 -j NSM_PREROUTE

Previous experiments returned this error on Proxy local:
```bash
kubectl logs $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-proxy
```
[  2294.311150s]  WARN ThreadId(01) inbound: linkerd_app_core::serve: Server failed to become ready error=inbound connections are not allowed on this IP address (172.16.1.2) error.sources=[inbound connections are not allowed on this IP address (172.16.1.2)] client.addr=172.16.1.3:48442

Experiment was made to find a rootcause:
PROXY_LOCAL pod was run with greeting container on it. You can find config file for it in cluster2/nse-auto-scale/pod-template-with-greeting.yaml
Even with greeting container on it, request returned the same error.
reason is that nsm address is not in allowed_ip here:
https://github.com/linkerd/linkerd2-proxy/blob/6b9003699b170dbbf240aa22f0b36db3f21cf14a/linkerd/app/core/src/transport/allow_ips.rs

Allowed_ips are equal to ips from LINKERD2_PROXY_INBOUND_IPS ENV https://github.com/linkerd/linkerd2/blob/f6c6ff965cae3accb49f061dca5c8edbdd9d13ef/charts/partials/templates/_proxy.tpl.
This constant is equal to pod status.podips value, defined here: https://github.com/linkerd/linkerd2/blob/f6c6ff965cae3accb49f061dca5c8edbdd9d13ef/charts/partials/templates/_proxy.tpl
Then practically the best way is to add rule into iptables to change destination before it come to linkerd-proxy:

How to solve:
iptables: change distination address from NSM to pod IP and send it into Proxy Redirect chain
   PROXY_LOCAL pod IP 10.244.1.49
   NSE addr: 172.16.1.2

   
16/09/22

WEB_LOCAL=web-local-67bfcd4d9c-5hqrm
PROXY_LOCAL=proxy-web-local-67bfcd4d9c-5hqrm
1.
Run PROXY_LOCAL pod with greeting container on it.
Apply IPtables onto PROXY_LOCAL pod:
   iptables -t nat -N NSM_PREROUTE
   iptables -t nat -A NSM_PREROUTE -j DNAT --to-destination 10.244.1.49
   iptables -t nat -A NSM_PREROUTE -j PROXY_INIT_REDIRECT
   iptables -t nat -I PREROUTING 1 -i nsm-linker-8839 -d 172.16.1.2 -j NSM_PREROUTE


Experiment works with greeting container on PROXY_LOCAL pod.

2. run PROXY_LOCAL without greeting container and repeat:

Apply same iptables on PROXY_LOCAL:
```bash
iptables -t nat -N NSM_PREROUTE
iptables -t nat -A NSM_PREROUTE -j DNAT --to-destination 10.244.2.40
iptables -t nat -A NSM_PREROUTE -j PROXY_INIT_REDIRECT
iptables -t nat -I PREROUTING 1 -i nsm-linker-d4b4 -d 172.16.1.2 -j NSM_PREROUTE
```
Result:
*   Trying 172.16.1.2:9080...
* connect to 172.16.1.2 port 9080 failed: Connection refused
* Failed to connect to 172.16.1.2 port 9080 after 8 ms: Connection refused
* Closing connection 0
  curl: (7) Failed to connect to 172.16.1.2 port 9080 after 8 ms: Connection refused
  command terminated with exit code 7


3. Update iptables rules so  destination chagne on greeting clusterIP 

iptables -t nat -D NSM_PREROUTE -j DNAT --to-destination 10.244.2.40
iptables -t nat -I NSM_PREROUTE 1 -j DNAT --to-destination 10.96.210.72
Result:
*   Trying 172.16.1.2:9080...
* connect to 172.16.1.2 port 9080 failed: Operation timed out
* Failed to connect to 172.16.1.2 port 9080 after 130439 ms: Operation timed out
* Closing connection 0
  curl: (28) Failed to connect to 172.16.1.2 port 9080 after 130439 ms: Operation timed out
  command terminated with exit code 28

WIRESHARK:

* tcp retransmission: 


4. Update iptables rules to change destination to greeting podIP:
Firstly, delete old rule:
```bash
iptables -t nat -D NSM_PREROUTE -j DNAT --to-destination 10.96.210.72
iptables -t nat -I NSM_PREROUTE 1 -j DNAT --to-destination 10.244.1.56

```
Result:
*   Trying 172.16.1.2:9080...
* connect to 172.16.1.2 port 9080 failed: Network unreachable
* Failed to connect to 172.16.1.2 port 9080 after 129520 ms: Network unreachable
* Closing connection 0
  curl: (7) Failed to connect to 172.16.1.2 port 9080 after 129520 ms: Network unreachable
  command terminated with exit code 7

5. Update iptables rules:
   iptables -t nat -D NSM_PREROUTE -j DNAT --to-destination 10.244.1.56
   iptables -t nat -D NSM_PREROUTE -j PROXY_INIT_REDIRECT
   iptables -t nat -D PREROUTING -i nsm-linker-d4b4 -d 172.16.1.2 -j NSM_PREROUTE

   iptables -t nat -A NSM_PREROUTE -d 172.16.1.2 -j DNAT --to-destination 10.244.2.40
   iptables -t nat -A NSM_PREROUTE -j PROXY_INIT_REDIRECT
   iptables -t nat -I PREROUTING 1 -i nsm-linker-d4b4 -j NSM_PREROUTE

didn't work

6. just redirect onto localhost

iptables -t nat -D NSM_PREROUTE -d 172.16.1.2 -j DNAT --to-destination 10.244.2.40
iptables -t nat -D NSM_PREROUTE -j PROXY_INIT_REDIRECT
iptables -t nat -D PREROUTING  -i nsm-linker-d4b4 -j NSM_PREROUTE


iptables -t nat -I PREROUTING 1 -p tcp -i nsm-linker-d4b4 -j DNAT --to-destination 127.0.0.1

7. no new rules, send request from PROXY_LOCAL to greeting via NSM address

listen loopback
to sniff traffic from particular interface, for example loopback, run: 
```bash
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -i lo -o proxy-local-linkerd.pcap
```

Next step:
Run debug onto Linkerd outbound port 4140


Useful links:
IPtables and how to use them (in Russian):
https://www.opennet.ru/docs/RUS/iptables/#TRAVERSINGOFTABLES
https://tokmakov.msk.ru/blog/item/473

Iptables in linkerd:
https://linkerd.io/2.12/reference/iptables/
https://linkerd.io/2021/09/23/how-linkerd-uses-iptables-to-transparently-route-kubernetes-traffic/
https://linkerd.io/2.11/features/protocol-detection/