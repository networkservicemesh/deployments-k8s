get shark dump:
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
  
  
```bash
# local 2
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c nse -o sniff_dump_greetint_on_proxy_local/proxy-local-nse.pcap
# local 3
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_greetint_on_proxy_local/proxy-local-linkerd.pcap
# local 4
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -o sniff_dump_exp3/web-local-nsc.pcap
```
Local
```bash
export KUBECONFIG=$KUBECONFIG2
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c web-svc -- /bin/sh -c 'curl -v -H "Connection: close" greeting.ns-nsm-linkerd:9080'
```

```bash
# local 2
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c nse -o sniff_dump_exp3/proxy-local-nse-from-nsc.pcap
# local 3
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_exp3/proxy-local-linkerd-from-nsc.pcap
# local 4
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -o sniff_dump_exp3/web-local-nsc-from-nsc.pcap
```

```bash
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" greeting.ns-nsm-linkerd:9080'
```
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v  172.16.1.2:9080'
kubectl exec -it $PROXY_LOCAL -n ns-nsm-linkerd -c nse -- ifconfig

```bash
# local 2
export KUBECONFIG=$KUBECONFIG1
kubectl sniff $WEB -n ns-nsm-linkerd -c cmd-nsc -o sniff_dump_exp3/web-nsc-from-web.pcap

# local 3
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY -n ns-nsm-linkerd -c nse -o sniff_dump_exp3/proxy-nse-from-web.pcap

export KUBECONFIG=$KUBECONFIG2
# local 4
kubectl sniff $PROXY -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_exp3/proxy-linkerd-from-web.pcap

# local
export KUBECONFIG=$KUBECONFIG1
kubectl exec -it $WEB -n ns-nsm-linkerd -c web-svc -- /bin/sh -c 'curl -v -H "Connection: close" greeting.ns-nsm-linkerd:9080'
```

```bash
# local 2
export KUBECONFIG=$KUBECONFIG1
kubectl sniff $WEB -n ns-nsm-linkerd -c cmd-nsc -o sniff_dump_exp3/web-nsc-from-nsc.pcap

# local 3
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY -n ns-nsm-linkerd -c nse -o sniff_dump_exp3/proxy-nse-from-nsc.pcap

export KUBECONFIG=$KUBECONFIG2
# local 4
kubectl sniff $PROXY -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_exp3/proxy-linkerd-from-nsc.pcap

# local
export KUBECONFIG=$KUBECONFIG1
kubectl exec -it $WEB -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" greeting.ns-nsm-linkerd:9080'
```

10.244.2.19 - proxy web local pod ip
172.16.1.2:9080
cluster IP 10.96.126.33
сделать positive example.
с proxy-web-local
curl greeting clusterIP

```bash
# local 2
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c nse -o sniff_dump_proxy_local_to_clusterip/proxy-local-nse.pcap
# local 3
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_proxy_local_to_clusterip/proxy-local-linkerd.pcap

export KUBECONFIG=$KUBECONFIG2
kubectl exec -it $PROXY_LOCAL -n ns-nsm-linkerd -c nse -- /bin/sh -c 'curl -v -H "Connection: close" 10.96.126.33:9080'
```

locally
c cmd-nsc web-local
curl cluster IP 10.96.126.33:9080 (to greeting)
```bash
# local 2
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c nse -o sniff_dump_web_local_to_clusterip/proxy-local-nse.pcap
# local 3
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_web_local_to_clusterip/proxy-local-linkerd.pcap

export KUBECONFIG=$KUBECONFIG2
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" 10.96.126.33:9080'
```

locally
c cmd-nsc web-local
curl 172.16.1.2:9080 (to proxy-local)
```bash
# local 2
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c nse -o sniff_dump_web_local_to_nsm_addr_16_09_exp1/proxy-local-nse.pcap
# local 3
export KUBECONFIG=$KUBECONFIG2
kubectl sniff $PROXY_LOCAL -n ns-nsm-linkerd -c linkerd-debug -o sniff_dump_web_local_to_nsm_addr_16_09_exp1/proxy-local-linkerd.pcap

export KUBECONFIG=$KUBECONFIG2
kubectl sniff $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -o sniff_dump_web_local_to_nsm_addr_16_09_exp1/web-nsc.pcap

export KUBECONFIG=$KUBECONFIG2
kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" 172.16.1.2:9080'
```
addr:172.16.1.3 - web local nsm address

exp 0 (no iprules)
amalysheva@ubuntu18gulevich:~$ kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" 172.16.1.2:9080'
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

kubectl exec -it $PROXY_LOCAL -n ns-nsm-linkerd -c nse -- /bin/sh
затем добавить Iptables.
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
amalysheva@ubuntu18gulevich:~$ kubectl exec -it $WEB_LOCAL -n ns-nsm-linkerd -c cmd-nsc -- /bin/sh -c 'curl -v -H "Connection: close" 172.16.1.2:9080'
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

1. добавить greeting container on proxy_local
 -> найти в коде Linkerd этот лог.
2. проверить работает ли loopback. catch lo interface.
3. залезть дебагом в linkerd
встать дебагером на outbound port 4140


16/09/22

WEB_LOCAL=web-local-67bfcd4d9c-5hqrm
PROXY_LOCAL=proxy-web-local-67bfcd4d9c-5hqrm

как решить проблему
[  2294.311150s]  WARN ThreadId(01) inbound: linkerd_app_core::serve: Server failed to become ready error=inbound connections are not allowed on this IP address (172.16.1.2) error.sources=[inbound connections are not allowed on this IP address (172.16.1.2)] client.addr=172.16.1.3:48442

Варианты:
1. iptables: change distination address from NSM to pod IP and send it into Proxy Redirect chain
   PROXY_LOCAL pod IP 10.244.1.49 
   NSE addr: 172.16.1.2

Apply IPtables:
   iptables -t nat -N NSM_PREROUTE
   iptables -t nat -A NSM_PREROUTE -j DNAT --to-destination 10.244.1.49
   iptables -t nat -A NSM_PREROUTE -j PROXY_INIT_REDIRECT
   iptables -t nat -I PREROUTING 1 -i nsm-linker-8839 -d 172.16.1.2 -j NSM_PREROUTE


эксперимент работает с запущенным greeting container на PROXY_LOCAL pod.

2. запустить PROXY_LOCAL без greeting container и повторить

iptables -t nat -N NSM_PREROUTE
iptables -t nat -A NSM_PREROUTE -j DNAT --to-destination 10.244.2.40
iptables -t nat -A NSM_PREROUTE -j PROXY_INIT_REDIRECT
iptables -t nat -I PREROUTING 1 -i nsm-linker-d4b4 -d 172.16.1.2 -j NSM_PREROUTE
Result:
*   Trying 172.16.1.2:9080...
* connect to 172.16.1.2 port 9080 failed: Connection refused
* Failed to connect to 172.16.1.2 port 9080 after 8 ms: Connection refused
* Closing connection 0
  curl: (7) Failed to connect to 172.16.1.2 port 9080 after 8 ms: Connection refused
  command terminated with exit code 7


3. обновить iptables rules так, чтобы destination менялся сразу на greeting clusterIP 

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

* tcp retransmission: попытка сконнектиться с портом три раза
* отпрпавляются запросы не с web local nsmIP, но с PodIP



4. обновить iptables rules так, чтобы destination менялся сразу на greeting podIP

iptables -t nat -D NSM_PREROUTE -j DNAT --to-destination 10.96.210.72
iptables -t nat -I NSM_PREROUTE 1 -j DNAT --to-destination 10.244.1.56
Result:
*   Trying 172.16.1.2:9080...
* connect to 172.16.1.2 port 9080 failed: Network unreachable
* Failed to connect to 172.16.1.2 port 9080 after 129520 ms: Network unreachable
* Closing connection 0
  curl: (7) Failed to connect to 172.16.1.2 port 9080 after 129520 ms: Network unreachable
  command terminated with exit code 7


5. поправить iptables rules
   iptables -t nat -D NSM_PREROUTE -j DNAT --to-destination 10.244.1.56
   iptables -t nat -D NSM_PREROUTE -j PROXY_INIT_REDIRECT
   iptables -t nat -D PREROUTING -i nsm-linker-d4b4 -d 172.16.1.2 -j NSM_PREROUTE

   iptables -t nat -A NSM_PREROUTE -d 172.16.1.2 -j DNAT --to-destination 10.244.2.40
   iptables -t nat -A NSM_PREROUTE -j PROXY_INIT_REDIRECT
   iptables -t nat -I PREROUTING 1 -i nsm-linker-d4b4 -j NSM_PREROUTE


6. just redirect onto localhost

iptables -t nat -D NSM_PREROUTE -d 172.16.1.2 -j DNAT --to-destination 10.244.2.40
iptables -t nat -D NSM_PREROUTE -j PROXY_INIT_REDIRECT
iptables -t nat -D PREROUTING  -i nsm-linker-d4b4 -j NSM_PREROUTE


iptables -t nat -I PREROUTING 1 -p tcp -i nsm-linker-d4b4 -j DNAT --to-destination 127.0.0.1

7. no new rules, send request from PROXY_LOCAL to greeting via NSM address

listen loopback
   
4. Каким-то образом подставить NSM address into linkerd LINKERD2_PROXY_INBOUND_IPS:
   A. подставить в status.PodIPs - похоже это невозможно
   B. сконфигурировать proxy так, чтобы он брал не только v1.status.podIPs, но и nsm address. тут проблема в том, что linkerd-init запускается первым на поде. потом nsm-init