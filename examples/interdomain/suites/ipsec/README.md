# IPSec interdomain examples

Unlike the [basic setup](../basic), which uses `Wireguard` as the default IP remote mechanism, we prioritize `IPSec` here.

## Requires

Please make sure to follow the steps from [ipsec multicluster NSM setup](../../three_cluster_configuration/ipsec)

## Includes

- [Kernel to IP to Kernel Connection](../../usecases/interdomain_Kernel2IP2Kernel)
- [Kernel to IP to Kernel Connection via floating registry](../../usecases/floating_Kernel2IP2Kernel)
- [Kernel to IP to Memif Connection via floating registry](../../usecases/floating_Kernel2IP2Memif)
- [Memif to IP to Kernel Connection via floating registry](../../usecases/floating_Memif2IP2Kernel)
- [Memif to IP to Memif Connection via floating registry](../../usecases/floating_Memif2IP2Memif)
