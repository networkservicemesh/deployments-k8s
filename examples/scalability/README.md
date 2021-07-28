# Scalability tests

This folder contains scalability tests.

These tests can technically be run manually, like all other tests,
however they are meant to be run only automatically,
for better precision of measurements.

These tests require you to write a file with test params before each test run.
This file must be placed in the [cases](./cases) folder (near other .sh files),
and must have the following structure:
```bash
#!/bin/bash
TEST_NS_COUNT=1
TEST_NSE_COUNT=1
TEST_NSC_COUNT=1
TEST_REMOTE_CASE=false
```

## Requires

- [Basic NSM setup](./nsm_setup)
- [Prometheus](./prometheus)
- [Gnuplot deployment](./gnuplot)

## Includes

- [Single start without heal](./cases/SingleStart)
- [Single start with unsuccessful heal](./cases/DryHeal)
- [Clients restart](./cases/ClientsRestart)
- [Endpoints restart: successful heal](./cases/Heal)
