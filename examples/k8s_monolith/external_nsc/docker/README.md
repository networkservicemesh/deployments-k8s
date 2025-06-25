## Start docker container

This example shows how to start docker container using `docker compose`

## Run

Create kustomization file for the kind cluster:
```bash
cat > docker-compose.override.yaml <<EOF
---
networks:
  kind:
    external: true

services:
  nsc-simple-docker:
    networks:
      - kind
    environment:
      NSM_NETWORK_SERVICES: kernel://kernel2ip2kernel-monolith-nsc@k8s.nsm/nsm-1
EOF
```

Download docker-compose base file:
```bash
curl https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/758d36f8cbcf722a8a69bddf2b9fd3b3e861e2fa/apps/nsc-simple-docker/docker-compose.yaml -o docker-compose.yaml
```

Run docker-nsc:
```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d
```

## Cleanup

```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml down
```
```bash
rm docker-compose.yaml
```
