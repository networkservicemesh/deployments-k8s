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
EOF
```

Download docker compose base file:
```bash
curl https://raw.githubusercontent.com/networkservicemesh/deployments-k8s/afd9611bc80f3f1e4b69ea469447d6ce634be22e/apps/nse-simple-vl3-docker/docker-compose.yaml -o docker-compose.yaml
```

Run docker-nse:
```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d
```

## Cleanup

```bash
docker compose -f docker-compose.yaml -f docker-compose.override.yaml down
```
