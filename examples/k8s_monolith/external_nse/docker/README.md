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
  nse-simple-vl3-docker:
    networks:
      - kind
    environment:
      NSM_SERVICE_NAMES: kernel2ip2kernel-monolith-nse
      NSM_REGISTER_SERVICE: false
EOF
```

Download docker compose base file:
```bash
curl https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/8e255bf778ecd23d8f2af076d08dacf4717c5c04/apps/nse-simple-vl3-docker/docker-compose.yaml -o docker-compose.yaml
```

Run docker-nse:
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
