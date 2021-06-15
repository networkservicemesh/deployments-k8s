# Heal examples

This document contains links for heal examples of NSM.

## Requires

To run any heal example follow steps for [Basic NSM setup](../basic)

## Includes

- [Local Forwarder restart](./local-forwarder-healing)
- [Remote Forwarder restart](./remote-forwarder-healing)
- [Local NSMgr restart](./local-nsmgr-restart)
- [Remote NSMgr restart](./remote-nsmgr-restart)
- [Remote NSMgr death](./remote-nsmgr-death)
- [Registry restart](./registry-restart)

## Run

Create NSMgr token timeout to 10s patch:
```bash
cat > patch-nsmgr.yaml <<EOF
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nsmgr
spec:
  template:
    spec:
      containers:
        - name: nsmgr
          env:
            - name: NSM_MAX_TOKEN_LIFETIME
              value: 10s
EOF
```

Create Forwarder token timeout to 10s patch:
```bash
cat > patch-forwarder.yaml <<EOF
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: forwarder-vpp
spec:
  template:
    spec:
      containers:
        - name: forwarder-vpp
          env:
            - name: NSM_MAX_TOKEN_LIFETIME
              value: 10s
EOF
```

Apply patches:
```bash
kubectl apply -k .
```