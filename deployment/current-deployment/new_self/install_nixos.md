master 1 is oraclearm2

master 2 is k3s-local-01

before run wireguard mesh thingie to bridge it all together

## to deploy cilium
helm install cilium cilium/cilium --namespace=kube-system --values=cilium_values_nixos.yaml 
## to upgrade when changes in values file
helm upgrade cilium cilium/cilium  --namespace=kube-system --values=cilium_values_nixos.yaml

<!-- ## to upgrade to new cilium version
helm upgrade cilium cilium/cilium  --namespace=kube-system --version 1.15.4 --values=cilium_values.yaml -->

## to add the loadbalancer ip pool and other requirements
kubectl apply -f cilium_config.yaml



## add snapshot controller task
kubectl apply -f snapshot_controller/snapshot_controller.yaml
